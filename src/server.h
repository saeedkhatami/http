#ifndef SERVER_H
#define SERVER_H

#include <stddef.h>
#include <time.h>

#define HTTP_METHOD_GET     1
#define HTTP_METHOD_HEAD    2
#define HTTP_METHOD_POST    3
#define HTTP_METHOD_PUT     4
#define HTTP_METHOD_DELETE  5
#define HTTP_METHOD_CONNECT 6
#define HTTP_METHOD_OPTIONS 7
#define HTTP_METHOD_TRACE   8
#define HTTP_METHOD_PATCH   9

#define MAX_HEADERS 32
#define MAX_HEADER_NAME 64
#define MAX_HEADER_VALUE 256
#define MAX_PATH 256
#define MAX_METHOD 16
#define MAX_VERSION 16
#define MAX_STATUS_MSG 32
#define MAX_REQUEST_BODY 8192
#define BUFFER_SIZE 8192

struct http_request {
    char method[MAX_METHOD];
    int method_type;
    char path[MAX_PATH];
    char version[MAX_VERSION];
    struct {
        char name[MAX_HEADER_NAME];
        char value[MAX_HEADER_VALUE];
    } headers[MAX_HEADERS];
    int header_count;
    char* body;
    size_t body_length;
    time_t timestamp;
};

// Assembly function declarations
extern int parse_http_request(const char* buffer, struct http_request* request);
extern void send_http_response(int fd, const char* data, size_t length);
extern int str_compare(const char* str1, const char* str2);
extern void debug_log(const char* msg, size_t len);
extern int get_method_type(const char* method);

#endif // SERVER_H