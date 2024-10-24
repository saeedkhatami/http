CC=gcc
CFLAGS=-Wall -O2
ASM=nasm
ASMFLAGS=-f elf64

all: http_server

http_server: main.o server_asm.o
	$(CC) $(CFLAGS) -o http_server main.o server_asm.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

server_asm.o: server_asm.asm
	$(ASM) $(ASMFLAGS) server_asm.asm

clean:
	rm -f http_server *.o