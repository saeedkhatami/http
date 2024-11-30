#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include <errno.h>
#include <fcntl.h>
#include "server.h"

#define PORT 8080
#define MAX_CONNECTIONS 10
#define DEBUG 1

int server_socket;

void handle_signal(int sig)
{
    printf("\nReceived signal %d. Shutting down server...\n", sig);
    if (server_socket > 0)
    {
        close(server_socket);
    }
    exit(0);
}

void set_nonblocking(int sock)
{
    int flags = fcntl(sock, F_GETFL, 0);
    if (flags == -1)
    {
        perror("fcntl F_GETFL");
        return;
    }
    if (fcntl(sock, F_SETFL, flags | O_NONBLOCK) == -1)
    {
        perror("fcntl F_SETFL O_NONBLOCK");
    }
}

void debug_print_request(struct http_request *request)
{
    if (!DEBUG)
        return;

    printf("\n=== HTTP Request ===\n");
    printf("Method: %s\n", request->method);
    printf("Path: %s\n", request->path);
    printf("Headers (%d):\n", request->header_count);
    for (uint32_t i = 0; i < request->header_count; i++)
    {
        printf("  %s: %s\n", request->headers[i].name, request->headers[i].value);
    }
    printf("==================\n\n");
}

int setup_server_socket()
{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0)
    {
        perror("Error creating socket");
        return -1;
    }

    int opt = 1;
    if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt)) < 0)
    {
        perror("Error setting socket options");
        close(sock);
        return -1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Error binding socket");
        close(sock);
        return -1;
    }

    if (listen(sock, MAX_CONNECTIONS) < 0)
    {
        perror("Error listening");
        close(sock);
        return -1;
    }

    return sock;
}

int main()
{

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    server_socket = setup_server_socket();
    if (server_socket < 0)
    {
        fprintf(stderr, "Failed to setup server socket\n");
        exit(1);
    }

    printf("Server listening on port %d\n", PORT);

    struct sockaddr_in client_addr;
    socklen_t client_len = sizeof(client_addr);

    while (1)
    {

        int client_fd = accept(server_socket, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0)
        {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
            {
                continue;
            }
            perror("Error accepting connection");
            continue;
        }

        set_nonblocking(client_fd);

        char client_ip[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(client_addr.sin_addr), client_ip, INET_ADDRSTRLEN);
        if (DEBUG)
        {
            printf("New connection from %s:%d\n",
                   client_ip,
                   ntohs(client_addr.sin_port));
        }

        struct http_request request;
        memset(&request, 0, sizeof(request));

        int parse_result = parse_http_request(client_fd, &request);
        if (parse_result == 0)
        {
            if (DEBUG)
            {
                debug_print_request(&request);
            }

            handle_client(client_fd, &request);
        }
        else
        {
            if (DEBUG)
            {
                printf("Failed to parse HTTP request from %s\n", client_ip);
            }
        }

        close(client_fd);
    }

    close(server_socket);
    return 0;
}