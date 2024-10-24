#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>

#define PORT 8080
#define MAX_EVENTS 10
#define BUFFER_SIZE 4096
#define MAX_PATH_LENGTH 256
#define MAX_METHOD_LENGTH 16

// assembly function
extern int parse_http_request(char* buffer, char* method, char* path);
extern void send_http_response(int fd, const char* data, size_t length);
extern int str_compare(const char* str1, const char* str2);
extern void debug_log(const char* msg, size_t len);

// HTTP Response
const char* HTTP_OK = "HTTP/1.1 200 OK\r\n"
                     "Server: Hybrid C/ASM Server\r\n"
                     "Content-Type: text/plain\r\n"
                     "Content-Length: %d\r\n"
                     "Connection: close\r\n\r\n";

const char* HTTP_NOT_FOUND = "HTTP/1.1 404 Not Found\r\n"
                           "Server: Hybrid C/ASM Server\r\n"
                           "Content-Type: text/plain\r\n"
                           "Content-Length: 14\r\n"
                           "Connection: close\r\n\r\n"
                           "Page not found\r\n";

// toute
struct Route {
    const char* path;
    const char* response;
    size_t response_len;
};

static struct Route routes[] = {
    {"/", "Welcome to the server!\r\n", 34},
    {"/about", "About page served by Assembly.\r\n", 29},
    {"/contact", "Contact page served by Assembly.\r\n", 31},
    {NULL, NULL, 0}
};

static int create_server_socket(void);
static int make_socket_non_blocking(int fd);
static void handle_client(int client_fd);
static void handle_get_request(int client_fd, const char* path);

int main() {
    debug_log("Starting server\n", 27);
    
    int server_fd = create_server_socket();
    if (server_fd < 0) return 1;

    int epoll_fd = epoll_create1(0);
    if (epoll_fd < 0) {
        perror("epoll_create1");
        return 1;
    }

    struct epoll_event ev = {0};
    ev.events = EPOLLIN;
    ev.data.fd = server_fd;
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, server_fd, &ev) < 0) {
        perror("epoll_ctl");
        return 1;
    }

    debug_log("Entering event loop\n", 19);
    struct epoll_event events[MAX_EVENTS];

    while (1) {
        int nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
        if (nfds < 0) {
            perror("epoll_wait");
            continue;
        }

        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == server_fd) {
                struct sockaddr_in client_addr;
                socklen_t client_len = sizeof(client_addr);
                int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
                
                if (client_fd < 0) {
                    perror("accept");
                    continue;
                }

                make_socket_non_blocking(client_fd);

                struct epoll_event client_ev = {0};
                client_ev.events = EPOLLIN | EPOLLET;
                client_ev.data.fd = client_fd;
                if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, client_fd, &client_ev) < 0) {
                    perror("epoll_ctl: client_fd");
                    close(client_fd);
                }
            } else {
                handle_client(events[i].data.fd);
            }
        }
    }

    close(server_fd);
    close(epoll_fd);
    return 0;
}

static int create_server_socket(void) {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return -1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        perror("setsockopt");
        return -1;
    }

    struct sockaddr_in server_addr = {0};
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("bind");
        return -1;
    }

    if (listen(server_fd, 5) < 0) {
        perror("listen");
        return -1;
    }

    return server_fd;
}

static int make_socket_non_blocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags == -1) return -1;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

static void handle_client(int client_fd) {
    char buffer[BUFFER_SIZE];
    char method[MAX_METHOD_LENGTH];
    char path[MAX_PATH_LENGTH];
    
    ssize_t bytes_read = read(client_fd, buffer, BUFFER_SIZE - 1);
    if (bytes_read <= 0) {
        close(client_fd);
        return;
    }
    buffer[bytes_read] = '\0';

    if (parse_http_request(buffer, method, path) < 0) {
        send_http_response(client_fd, HTTP_NOT_FOUND, strlen(HTTP_NOT_FOUND));
        close(client_fd);
        return;
    }

    if (str_compare(method, "GET") == 0) {
        handle_get_request(client_fd, path);
    } else {
        send_http_response(client_fd, HTTP_NOT_FOUND, strlen(HTTP_NOT_FOUND));
    }

    close(client_fd);
}

static void handle_get_request(int client_fd, const char* path) {
    for (int i = 0; routes[i].path != NULL; i++) {
        if (str_compare(path, routes[i].path) == 0) {
            char response[BUFFER_SIZE];
            int header_len = snprintf(response, BUFFER_SIZE, HTTP_OK, routes[i].response_len);
            memcpy(response + header_len, routes[i].response, routes[i].response_len);
            send_http_response(client_fd, response, header_len + routes[i].response_len);
            return;
        }
    }
    send_http_response(client_fd, HTTP_NOT_FOUND, strlen(HTTP_NOT_FOUND));
}