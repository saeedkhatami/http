#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include "server.h"

// MIME type mapping structure
struct mime_type {
    const char* extension;
    const char* type;
};

// MIME type lookup table
static const struct mime_type MIME_TYPES[] = {
    {".html", "text/html"},
    {".css",  "text/css"},
    {".js",   "application/javascript"},
    {".json", "application/json"},
    {".png",  "image/png"},
    {".jpg",  "image/jpeg"},
    {".jpeg", "image/jpeg"},
    {".gif",  "image/gif"},
    {".txt",  "text/plain"},
    {NULL,    "application/octet-stream"}  // Default type
};

// HTTP status codes and messages
static const struct {
    int code;
    const char* message;
} HTTP_STATUS[] = {
    {200, "OK"},
    {400, "Bad Request"},
    {404, "Not Found"},
    {500, "Internal Server Error"},
    {0, NULL}
};

// Error messages lookup table
static const char* ERROR_MESSAGES[] = {
    [SERVER_OK] = "Success",
    [SERVER_ERROR] = "General server error",
    [SERVER_PARSE_ERROR] = "Request parsing failed",
    [SERVER_READ_ERROR] = "File read error",
    [SERVER_WRITE_ERROR] = "Socket write error",
    [SERVER_MEM_ERROR] = "Memory allocation error"
};

const char* get_error_str(int error_code) {
    error_code = -error_code;  // Convert to positive index
    if (error_code >= 0 && error_code < (int)(sizeof(ERROR_MESSAGES)/sizeof(char*))) {
        return ERROR_MESSAGES[error_code];
    }
    return "Unknown error";
}

void log_error(const char* function_name, int error_code) {
    DEBUG_ERROR_PRINT("%s failed: %s (errno: %d - %s)", 
        function_name, 
        get_error_str(error_code),
        errno,
        strerror(errno));
}

static const char* get_mime_type(const char* filepath) {
    const char* extension = strrchr(filepath, '.');
    if (!extension) {
        return MIME_TYPES[sizeof(MIME_TYPES)/sizeof(MIME_TYPES[0]) - 1].type;
    }

    for (size_t i = 0; MIME_TYPES[i].extension != NULL; i++) {
        if (strcasecmp(extension, MIME_TYPES[i].extension) == 0) {
            return MIME_TYPES[i].type;
        }
    }

    return MIME_TYPES[sizeof(MIME_TYPES)/sizeof(MIME_TYPES[0]) - 1].type;
}

static const char* get_status_message(int status_code) {
    for (size_t i = 0; HTTP_STATUS[i].message != NULL; i++) {
        if (HTTP_STATUS[i].code == status_code) {
            return HTTP_STATUS[i].message;
        }
    }
    return "Unknown Status";
}

void cleanup_request(struct http_request* request) {
    if (!request) return;
    
    if (request->body) {
        free(request->body);
        request->body = NULL;
    }
    request->body_length = 0;
    request->header_count = 0;
}

int read_file(const char* filepath, char* buffer, size_t max_size) {
    if (!filepath || !buffer || max_size == 0) {
        DEBUG_ERROR_PRINT("Invalid parameters in read_file");
        return SERVER_ERROR;
    }

    int fd = open(filepath, O_RDONLY);
    if (fd < 0) {
        log_error("open", SERVER_READ_ERROR);
        return SERVER_READ_ERROR;
    }

    struct stat st;
    if (fstat(fd, &st) < 0) {
        log_error("fstat", SERVER_READ_ERROR);
        close(fd);
        return SERVER_READ_ERROR;
    }

    if (st.st_size > (off_t)max_size) {
        DEBUG_ERROR_PRINT("File too large: %ld bytes (max: %zu)", st.st_size, max_size);
        close(fd);
        return SERVER_ERROR;
    }

    ssize_t bytes_read = read(fd, buffer, st.st_size);
    if (bytes_read < 0 || bytes_read != st.st_size) {
        log_error("read", SERVER_READ_ERROR);
        close(fd);
        return SERVER_READ_ERROR;
    }

    close(fd);
    return bytes_read;
}

int serve_file(int client_fd, const char* path) {
    DEBUG_INFO_PRINT("Serving file: %s", path);

    char file_path[MAX_PATH_LEN] = "public";
    strncat(file_path, path, MAX_PATH_LEN - 7);  // 7 = len("public") + 1

    // Handle root path
    if (strcmp(path, "/") == 0) {
        strncat(file_path, "index.html", MAX_PATH_LEN - strlen(file_path) - 1);
    }

    char response[MAX_RESPONSE_SIZE];
    char content[MAX_RESPONSE_SIZE - 512];  // Reserve space for headers
    int content_length;

    content_length = read_file(file_path, content, sizeof(content));
    if (content_length < 0) {
        const char* error_page = "<html><body><h1>404 Not Found</h1></body></html>";
        int header_len = snprintf(response, sizeof(response),
            "HTTP/1.1 404 Not Found\r\n"
            "Content-Type: text/html\r\n"
            "Content-Length: %zu\r\n"
            "Connection: close\r\n"
            "\r\n"
            "%s",
            strlen(error_page), error_page);

        if (send_http_response(client_fd, response, header_len) < 0) {
            log_error("send_http_response", SERVER_WRITE_ERROR);
            return SERVER_WRITE_ERROR;
        }
        return SERVER_OK;
    }

    const char* mime_type = get_mime_type(file_path);
    int header_len = snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "\r\n",
        mime_type, content_length);

    if (send_http_response(client_fd, response, header_len) < 0 ||
        send_http_response(client_fd, content, content_length) < 0) {
        log_error("send_http_response", SERVER_WRITE_ERROR);
        return SERVER_WRITE_ERROR;
    }

    DEBUG_VERBOSE_PRINT("Successfully served file: %s (%d bytes)", file_path, content_length);
    return SERVER_OK;
}

void handle_client(int client_fd, struct http_request* request) {
    if (!request) {
        DEBUG_ERROR_PRINT("Invalid request pointer");
        return;
    }

    DEBUG_INFO_PRINT("Handling client request for path: %s", request->path);

    if (request->method != HTTP_METHOD_GET) {
        const char* error_msg = "<html><body><h1>405 Method Not Allowed</h1></body></html>";
        char response[512];
        int len = snprintf(response, sizeof(response),
            "HTTP/1.1 405 Method Not Allowed\r\n"
            "Content-Type: text/html\r\n"
            "Content-Length: %zu\r\n"
            "Allow: GET\r\n"
            "Connection: close\r\n"
            "\r\n"
            "%s",
            strlen(error_msg), error_msg);

        if (send_http_response(client_fd, response, len) < 0) {
            log_error("send_http_response", SERVER_WRITE_ERROR);
        }
        return;
    }

    if (serve_file(client_fd, request->path) != SERVER_OK) {
        DEBUG_ERROR_PRINT("Failed to serve file for path: %s", request->path);
    }
}