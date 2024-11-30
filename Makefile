CC = gcc
NASM = nasm
CFLAGS = -Wall -g -fPIE
NASMFLAGS = -f elf64 -g -F dwarf -i src/
LDFLAGS = -pie -no-pie

C_SRCS = src/main.c
ASM_SRCS = src/server_asm.asm
OBJS = $(C_SRCS:.c=.o) $(ASM_SRCS:.asm=.o)

TARGET = http_server

.PHONY: all clean

all: src/server_constants.inc $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -no-pie -o $(TARGET)

%.o: %.c src/server_constants.inc
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm src/server_constants.inc
	$(NASM) $(NASMFLAGS) $< -o $@

src/server_constants.inc:
	@echo "; DO NOT EDIT" > $@
	@echo "%define HTTP_METHOD_GET     1 " >> $@
	@echo "%define HTTP_METHOD_HEAD    2" >> $@
	@echo "%define HTTP_METHOD_POST    3" >> $@
	@echo "%define HTTP_METHOD_PUT     4" >> $@
	@echo "%define HTTP_METHOD_DELETE  5" >> $@
	@echo "%define HTTP_METHOD_CONNECT 6" >> $@
	@echo "%define HTTP_METHOD_OPTIONS 7" >> $@
	@echo "%define HTTP_METHOD_TRACE   8" >> $@
	@echo "%define HTTP_METHOD_PATCH   9" >> $@
	@echo "%define MAX_HEADERS 32" >> $@
	@echo "%define MAX_HEADER_NAME 64" >> $@
	@echo "%define MAX_HEADER_VALUE 256" >> $@
	@echo "%define MAX_PATH 256" >> $@
	@echo "%define MAX_METHOD 16" >> $@
	@echo "%define MAX_VERSION 16" >> $@
	@echo "%define MAX_STATUS_MSG 32" >> $@
	@echo "%define MAX_REQUEST_BODY 8192" >> $@
	@echo "%define BUFFER_SIZE 8192" >> $@

clean:
	rm -f $(OBJS) $(TARGET) src/server_constants.inc