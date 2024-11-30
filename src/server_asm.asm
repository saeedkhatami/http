section .data
    debug_parse_msg db "Parsing HTTP request...", 10, 0
    debug_method_msg db "Method: ", 0
    debug_path_msg db "Path: ", 0
    debug_header_msg db "Header: ", 0
    debug_value_msg db "Value: ", 0
    newline db 10, 0

    err_invalid_method db "Invalid HTTP method", 0
    err_path_too_long db "Request path too long", 0
    err_header_too_long db "Header too long", 0
    err_too_many_headers db "Too many headers", 0
    err_malformed db "Malformed request", 0

    method_get db "GET", 0
    method_post db "POST", 0
    method_head db "HEAD", 0
    method_put db "PUT", 0
    method_delete db "DELETE", 0

    BUFFER_SIZE equ 8192
    METHOD_SIZE equ 16
    PATH_SIZE equ 256
    HEADER_SIZE equ 64
    VALUE_SIZE equ 256

section .bss
    read_buffer resb BUFFER_SIZE
    tmp_buffer resb BUFFER_SIZE

section .text
    global parse_http_request
    global send_http_response
    global str_compare
    
    extern printf
    extern strlen
    extern strncpy
    extern write
    extern read

str_compare:
    push rbp
    mov rbp, rsp
    
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    
    test al, al
    jz .check_end
    test bl, bl
    jz .not_equal
    
    cmp al, bl
    jne .not_equal
    
    inc rdi
    inc rsi
    jmp .loop

.check_end:
    test bl, bl
    jz .equal
    
.not_equal:
    mov rax, 1
    jmp .done
    
.equal:
    xor rax, rax
    
.done:
    pop rbp
    ret

parse_http_request:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi    
    mov r13, rsi    
    mov rdi, r12
    mov rsi, read_buffer
    mov rdx, BUFFER_SIZE
    call read

    cmp rax, 0
    jle .read_error

    mov r14, rax
    mov rdi, read_buffer
    mov rsi, r13

    call parse_method
    test rax, rax
    jnz .parse_error

    mov rdi, read_buffer
    add rdi, rax    
    mov rsi, r13
    call parse_path
    test rax, rax
    jnz .parse_error

    xor r15, r15    
.parse_headers_loop:
    cmp r15, 32     
    jge .too_many_headers

    mov rdi, read_buffer
    add rdi, rax    
    cmp word [rdi], 0x0A0D  
    je .parsing_complete

    mov rsi, r13
    mov rdx, r15
    call parse_header
    test rax, rax
    jnz .parse_error

    inc r15
    jmp .parse_headers_loop

.parsing_complete:
    mov [r13 + 8], r15d  

    xor rax, rax    
    jmp .cleanup

.read_error:
    mov rax, -3     
    jmp .cleanup

.parse_error:
    mov rax, -2     
    jmp .cleanup

.too_many_headers:
    mov rax, -4     

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

send_http_response:
    push rbp
    mov rbp, rsp
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi    
    mov r13, rsi    
    mov rbx, rdx    
    mov rdi, r12    
    mov rsi, r13    
    mov rdx, rbx    
    call write
    
    cmp rax, 0
    jl .write_error
    
    cmp rax, rbx
    jne .partial_write
    
    jmp .done

.write_error:
    mov rax, -4     
    jmp .cleanup

.partial_write:
    mov rax, -5     

.done:
.cleanup:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

parse_method:
    push rbp
    mov rbp, rsp

    pop rbp
    ret

parse_path:
    push rbp
    mov rbp, rsp
    
    pop rbp
    ret

parse_header:
    push rbp
    mov rbp, rsp
    
    pop rbp
    ret

%ifdef DEBUG
section .data
    debug_fmt db "%s", 10, 0

section .text
debug_print:
    push rbp
    mov rbp, rsp

    mov rdi, debug_fmt
    mov rsi, rax    
    xor rax, rax    
    call printf
    
    pop rbp
    ret
%endif