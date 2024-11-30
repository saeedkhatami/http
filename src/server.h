#ifndef SERVER_H
#define SERVER_H

#include <stdint.h>

// Debug levels
#define DEBUG_NONE    0
#define DEBUG_ERROR   1
#define DEBUG_INFO    2
#define DEBUG_VERBOSE 3

// Current debug level - can be changed at compile time
#ifndef DEBUG_LEVEL
#define DEBUG_LEVEL DEBUG_INFO
#endif

// Error codes
#define SERVER_OK           0
#define SERVER_ERROR       -1
#define SERVER_PARSE_ERROR -2
#define SERVER_READ_ERROR  -3
#define SERVER_WRITE_ERROR -4
#define SERVER_MEM_ERROR   -5

// HTTP Methods
enum http_method {
    HTTP_METHOD_GET,
    HTTP_METHOD_POST,
    HTTP_METHOD_HEAD,
    HTTP_METHOD_PUT,
    HTTP_METHOD_DELETE,
    HTTP_METHOD_OPTIONS,
    HTTP_METHOD_PATCH,
    HTTP_METHOD_CONNECT,
    HTTP_METHOD_TRACE,
    HTTP_METHOD_UNKNOWN
};

// Maximum sizes
#define MAX_METHOD_LEN     16
#define MAX_PATH_LEN       256
#define MAX_HEADER_NAME    64
#define MAX_HEADER_VALUE   256
#define MAX_HEADERS        32
#define MAX_REQUEST_SIZE   8192
#define MAX_RESPONSE_SIZE  8192

// HTTP Header structure
struct http_header {
    char name[MAX_HEADER_NAME];
    char value[MAX_HEADER_VALUE];
};

// HTTP Request structure
struct http_request {
    enum http_method method;
    char method_str[MAX_METHOD_LEN];
    char path[MAX_PATH_LEN];
    uint32_t header_count;
    struct http_header headers[MAX_HEADERS];
    char* body;
    size_t body_length;
};

// Debug macros
#if DEBUG_LEVEL >= DEBUG_ERROR
    #define DEBUG_ERROR_PRINT(fmt, ...) \
        fprintf(stderr, "[ERROR] " fmt "\n", ##__VA_ARGS__)
#else
    #define DEBUG_ERROR_PRINT(fmt, ...)
#endif

#if DEBUG_LEVEL >= DEBUG_INFO
    #define DEBUG_INFO_PRINT(fmt, ...) \
        printf("[INFO] " fmt "\n", ##__VA_ARGS__)
#else
    #define DEBUG_INFO_PRINT(fmt, ...)
#endif

#if DEBUG_LEVEL >= DEBUG_VERBOSE
    #define DEBUG_VERBOSE_PRINT(fmt, ...) \
        printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
#else
    #define DEBUG_VERBOSE_PRINT(fmt, ...)
#endif

// Function prototypes - Assembly implementations
int parse_http_request(int client_fd, struct http_request* request);
int send_http_response(int client_fd, const char* response, size_t length);
int str_compare(const char* s1, const char* s2);

// Function prototypes - C implementations
void handle_client(int client_fd, struct http_request* request);
int read_file(const char* filepath, char* buffer, size_t max_size);
int serve_file(int client_fd, const char* path);

// Error handling helpers
const char* get_error_str(int error_code);
void log_error(const char* function_name, int error_code);
void cleanup_request(struct http_request* request);

#endif // SERVER_H