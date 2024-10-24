CC = gcc
NASM = nasm
CFLAGS = -Wall -g
NASMFLAGS = -f elf64 -g -F dwarf -i src/

C_SRCS = src/main.c
ASM_SRCS = src/server_asm.asm
OBJS = $(C_SRCS:.c=.o) $(ASM_SRCS:.asm=.o)

TARGET = hybrid_server

.PHONY: all clean

all: src/server_constants.inc $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm
	$(NASM) $(NASMFLAGS) $< -o $@

src/server_constants.inc:
	@echo "; DO NOT EDIT" > $@
	@echo "%define MAX_HEADERS 32" >> $@
	@echo "%define MAX_HEADER_NAME 64" >> $@
	@echo "%define MAX_HEADER_VALUE 256" >> $@
	@echo "%define MAX_PATH 256" >> $@
	@echo "%define MAX_METHOD 16" >> $@

clean:
	rm -f $(OBJS) $(TARGET) src/server_constants.inc