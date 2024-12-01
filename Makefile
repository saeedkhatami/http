NASM=nasm
NASM_FLAGS=-f elf64
LD=ld
SRC=HTTP.asm
OBJ=HTTP.o
TARGET=HTTP

all: $(TARGET)

$(OBJ): $(SRC)
	$(NASM) $(NASM_FLAGS) $< -o $@

$(TARGET): $(OBJ)
	$(LD) $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all clean
