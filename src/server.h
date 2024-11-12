#ifndef SERVER_H
#define SERVER_H

#include <stddef.h>
#include <time.h>

#define MAX_HEADERS 32
#define MAX_HEADER_NAME 64
#define MAX_HEADER_VALUE 256
#define MAX_PATH 256
#define MAX_METHOD 16
#define MAX_VERSION 16
#define MAX_STATUS_MSG 32

struct http_request {
    char method[MAX_METHOD];
    char path[MAX_PATH];
    char version[MAX_VERSION];
    struct {
        char name[MAX_HEADER_NAME];
        char value[MAX_HEADER_VALUE];
    } headers[MAX_HEADERS];
    int header_count;
    time_t timestamp;
    char* body;
    size_t body_length;
};

struct http_response {
    int status_code;
    char status_msg[MAX_STATUS_MSG];
    struct {
        char name[MAX_HEADER_NAME];
        char value[MAX_HEADER_VALUE];
    } headers[MAX_HEADERS];
    int header_count;
    const char* body;
    size_t body_length;
};

extern int parse_http_request(const char* buffer, struct http_request* request);
extern void send_http_response(int fd, const char* data, size_t length);
extern int str_compare(const char* str1, const char* str2);
extern void debug_log(const char* msg, size_t len);

#endif // SERVER_H