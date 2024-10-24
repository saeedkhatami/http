#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include "server.h"

#define PORT 8080
#define BUFFER_SIZE 4096

#define VERSION_MAJOR 0
#define VERSION_MINOR 0
#define VERSION_PATCH 2

static const char* HOMEPAGE = "<!DOCTYPE html>\n"
                            "<html>\n"
                            "<head><title>Hybrid Server</title></head>\n"
                            "<body>\n"
                            "<h1>Welcome to Hybrid C/ASM Server!</h1>\n"
                            "<ul>\n"
                            "<li><a href='/about'>About</a></li>\n"
                            "<li><a href='/test'>Test</a></li>\n"
                            "</ul>\n"
                            "</body>\n"
                            "</html>\n";

static const char* ABOUT_PAGE = "<!DOCTYPE html>\n"
                               "<html>\n"
                               "<head><title>About</title></head>\n"
                               "<body>\n"
                               "<h1>About</h1>\n"
                               "<p>This server is implemented using C and Assembly!</p>\n"
                               "<a href='/'>Back to Home</a>\n"
                               "</body>\n"
                               "</html>\n";

static const char* HTTP_OK_TEMPLATE = 
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: %s\r\n"
    "Content-Length: %zu\r\n"
    "Connection: close\r\n"
    "\r\n";

static const char* HTTP_404 = 
    "HTTP/1.1 404 Not Found\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 130\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>404 Not Found</title></head>"
    "<body><h1>404 Not Found</h1><p>The requested page was not found.</p></body></html>";

static void handle_request(int client_fd) {
    char buffer[BUFFER_SIZE];
    struct http_request request;
    ssize_t bytes_received;

    bytes_received = read(client_fd, buffer, BUFFER_SIZE - 1);
    if (bytes_received <= 0) {
        debug_log("Error reading request\n", 20);
        return;
    }
    buffer[bytes_received] = '\0';

    if (parse_http_request(buffer, &request) < 0) {
        debug_log("Failed to parse request\n", 22);
        send_http_response(client_fd, HTTP_404, strlen(HTTP_404));
        return;
    }

    char log_buffer[512];
    snprintf(log_buffer, sizeof(log_buffer), "\nReceived %s request for %s\n", 
             request.method, request.path);
    debug_log(log_buffer, strlen(log_buffer));

    if (str_compare(request.method, "GET") == 0) {
        char response[BUFFER_SIZE];
        const char* content;
        const char* content_type = "text/html";
        size_t content_length;

        if (str_compare(request.path, "/") == 0) {
            content = HOMEPAGE;
            content_length = strlen(HOMEPAGE);
        }
        else if (str_compare(request.path, "/about") == 0) {
            content = ABOUT_PAGE;
            content_length = strlen(ABOUT_PAGE);
        }
        else {
            send_http_response(client_fd, HTTP_404, strlen(HTTP_404));
            return;
        }

        int header_len = snprintf(response, BUFFER_SIZE, 
                                HTTP_OK_TEMPLATE, 
                                content_type, 
                                content_length);
        
        memcpy(response + header_len, content, content_length);
        
        send_http_response(client_fd, response, header_len + content_length);
    }
    else {
        send_http_response(client_fd, HTTP_404, strlen(HTTP_404));
    }
}

void log_version_info() {
    char message[100];

    snprintf(message, sizeof(message), "Server started on port 8080\nVERSION: %d.%d.%d", 
             VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);

    debug_log(message, strlen(message));
}

int main() {
    int server_fd;
    struct sockaddr_in server_addr;

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 10) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }

    log_version_info();

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_addr_len = sizeof(client_addr);
        
        int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, 
                             &client_addr_len);
        
        if (client_fd < 0) {
            debug_log("Accept failed\n", 14);
            continue;
        }

        handle_request(client_fd);
        close(client_fd);
    }

    return 0;
}