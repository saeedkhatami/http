CC=gcc
NASM=nasm
CFLAGS=-Wall -g -fPIE -no-pie
LDFLAGS=-lc

all: http_server

http_server: main.o server_utils.o server_asm.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

main.o: main.c server.h
	$(CC) $(CFLAGS) -c main.c

server_utils.o: server_utils.c server.h
	$(CC) $(CFLAGS) -c server_utils.c

server_asm.o: server_asm.asm
	$(NASM) -f elf64 -g -F dwarf server_asm.asm

clean:
	rm -f *.o http_server
