#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "server.h"

#define PORT 8080
#define VERSION_MAJOR 0
#define VERSION_MINOR 0
#define VERSION_PATCH 3

static void handle_get_request(int client_fd, struct http_request* request);
static void handle_head_request(int client_fd, struct http_request* request);
static void handle_post_request(int client_fd, struct http_request* request);
static void handle_put_request(int client_fd, struct http_request* request);
static void handle_delete_request(int client_fd, struct http_request* request);
static void handle_options_request(int client_fd, struct http_request* request);
static void handle_trace_request(int client_fd, struct http_request* request);
static void handle_patch_request(int client_fd, struct http_request* request);

static const char* HTTP_OK_TEMPLATE =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: %s\r\n"
    "Content-Length: %zu\r\n"
    "Connection: close\r\n"
    "\r\n";

static const char* HOMEPAGE =
    "<html><body><h1>Welcome</h1></body></html>";

static const char* ABOUT_PAGE =
    "<html><body><h1>About</h1></body></html>";

static const char* HTTP_400 =
    "HTTP/1.1 400 Bad Request\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 97\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>400 Bad Request</title></head><body><h1>400 Bad Request</h1></body></html>";

static const char* HTTP_404 =
    "HTTP/1.1 404 Not Found\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 130\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>404 Not Found</title></head>"
    "<body><h1>404 Not Found</h1><p>The requested page was not found.</p></body></html>";

static const char* HTTP_501 =
    "HTTP/1.1 501 Not Implemented\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 103\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>501 Not Implemented</title></head><body><h1>501 Not Implemented</h1></body></html>";

static const char* HTTP_201 = 
    "HTTP/1.1 201 Created\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 106\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>201 Created</title></head>"
    "<body><h1>201 Created</h1><p>Resource created successfully.</p></body></html>";

static const char* HTTP_204 = 
    "HTTP/1.1 204 No Content\r\n"
    "Connection: close\r\n"
    "\r\n";

static const char* HTTP_405 = 
    "HTTP/1.1 405 Method Not Allowed\r\n"
    "Content-Type: text/html\r\n"
    "Content-Length: 144\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<html><head><title>405 Method Not Allowed</title></head>"
    "<body><h1>405 Method Not Allowed</h1><p>The requested method is not allowed.</p></body></html>";
    



static char* read_html_file(const char* filepath, size_t* content_length) {
    int fd = open(filepath, O_RDONLY);
    if (fd < 0) {
        *content_length = 0;
        return NULL;
    }

    struct stat st;
    if (fstat(fd, &st) < 0) {
        close(fd);
        *content_length = 0;
        return NULL;
    }

    char* buffer = malloc(st.st_size + 1);
    if (!buffer) {
        close(fd);
        *content_length = 0;
        return NULL;
    }

    ssize_t bytes_read = read(fd, buffer, st.st_size);
    close(fd);

    if (bytes_read != st.st_size) {
        free(buffer);
        *content_length = 0;
        return NULL;
    }

    buffer[st.st_size] = '\0';
    *content_length = st.st_size;
    return buffer;
}

static void handle_get_request(int client_fd, struct http_request* request) {
    char response[BUFFER_SIZE];
    const char* content_type = "text/html";
    char* file_content = NULL;
    size_t content_length = 0;

    if (str_compare(request->path, "/") == 0) {
        file_content = read_html_file("public/index.html", &content_length);
    } else if (str_compare(request->path, "/about") == 0) {
        file_content = read_html_file("public/about.html", &content_length);
    } else if (str_compare(request->path, "/contact") == 0) {
        file_content = read_html_file("public/contact.html", &content_length);
    } else {
        send_http_response(client_fd, HTTP_404, strlen(HTTP_404));
        return;
    }
    if (!file_content) {
        send_http_response(client_fd, HTTP_404, strlen(HTTP_404));
        return;
    }

    int header_len = snprintf(response, BUFFER_SIZE,
                              HTTP_OK_TEMPLATE,
                              content_type,
                              content_length);

    memcpy(response + header_len, file_content, content_length);
    send_http_response(client_fd, response, header_len + content_length);

    free(file_content);
}


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

    
    printf("Received request:\n%s\n", buffer);

    if (parse_http_request(buffer, &request) < 0) {
        printf("Failed to parse request\n");
        debug_log("Failed to parse request\n", 22);
        send_http_response(client_fd, HTTP_400, strlen(HTTP_400));
        return;
    }

    printf("Parsed request - Method: %s, Path: %s, Version: %s\n", 
           request.method, request.path, request.version);

    
    if (strncmp(request.version, "HTTP/1.", 7) != 0) {
        send_http_response(client_fd, HTTP_400, strlen(HTTP_400));
        return;
    }

    
    switch (request.method_type) {
        case HTTP_METHOD_GET:
            handle_get_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_HEAD:
            handle_head_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_POST:
            handle_post_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_PUT:
            handle_put_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_DELETE:
            handle_delete_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_OPTIONS:
            handle_options_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_TRACE:
            handle_trace_request(client_fd, &request);
            break;
            
        case HTTP_METHOD_PATCH:
            handle_patch_request(client_fd, &request);
            break;
            
        default:
            send_http_response(client_fd, HTTP_501, strlen(HTTP_501));
            break;
    }
}

static void handle_head_request(int client_fd, struct http_request* request) {
    char response[BUFFER_SIZE];
    const char* content_type = "text/html";
    size_t content_length;
    
    if (str_compare(request->path, "/") == 0) {
        content_length = strlen(HOMEPAGE);
    }
    else if (str_compare(request->path, "/about") == 0) {
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
    
    send_http_response(client_fd, response, header_len);
}

static void handle_post_request(int client_fd, struct http_request* request) {
    
    if (!request->body || request->body_length == 0) {
        send_http_response(client_fd, HTTP_400, strlen(HTTP_400));
        return;
    }

    
    
    char response[BUFFER_SIZE];
    const char* success_msg = "<html><body><h1>POST Successful</h1></body></html>";
    size_t content_length = strlen(success_msg);

    int header_len = snprintf(response, BUFFER_SIZE,
                            HTTP_OK_TEMPLATE,
                            "text/html",
                            content_length);

    memcpy(response + header_len, success_msg, content_length);
    send_http_response(client_fd, response, header_len + content_length);
}

static void handle_put_request(int client_fd, struct http_request* request) {
    
    if (!request->body || request->body_length == 0) {
        send_http_response(client_fd, HTTP_400, strlen(HTTP_400));
        return;
    }

    
    send_http_response(client_fd, HTTP_201, strlen(HTTP_201));
}

static void handle_delete_request(int client_fd, struct http_request* request) {
    
    
    send_http_response(client_fd, HTTP_204, strlen(HTTP_204));
}

static void handle_options_request(int client_fd, struct http_request* request) {
    const char* options_response = 
        "HTTP/1.1 200 OK\r\n"
        "Allow: GET, HEAD, POST, PUT, DELETE, OPTIONS, TRACE, PATCH\r\n"
        "Content-Length: 0\r\n"
        "Connection: close\r\n"
        "\r\n";
    
    send_http_response(client_fd, options_response, strlen(options_response));
}

static void handle_trace_request(int client_fd, struct http_request* request) {
    char response[BUFFER_SIZE];
    const char* content_type = "message/http";
    
    
    char trace_body[BUFFER_SIZE];
    int trace_len = snprintf(trace_body, BUFFER_SIZE,
                           "%s %s %s\r\n",
                           request->method,
                           request->path,
                           request->version);

    
    for (int i = 0; i < request->header_count; i++) {
        trace_len += snprintf(trace_body + trace_len, BUFFER_SIZE - trace_len,
                            "%s: %s\r\n",
                            request->headers[i].name,
                            request->headers[i].value);
    }

    int header_len = snprintf(response, BUFFER_SIZE,
                            HTTP_OK_TEMPLATE,
                            content_type,
                            trace_len);

    memcpy(response + header_len, trace_body, trace_len);
    send_http_response(client_fd, response, header_len + trace_len);
}

static void handle_patch_request(int client_fd, struct http_request* request) {
    
    if (!request->body || request->body_length == 0) {
        send_http_response(client_fd, HTTP_400, strlen(HTTP_400));
        return;
    }

    char response[BUFFER_SIZE];
    const char* success_msg = "<html><body><h1>PATCH Successful</h1></body></html>";
    size_t content_length = strlen(success_msg);

    int header_len = snprintf(response, BUFFER_SIZE,
                            HTTP_OK_TEMPLATE,
                            "text/html",
                            content_length);

    memcpy(response + header_len, success_msg, content_length);
    send_http_response(client_fd, response, header_len + content_length);
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