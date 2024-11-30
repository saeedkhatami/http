; Server Assembly Functions
section .data
    ; Debug messages
    debug_parse_msg db "Parsing HTTP request...", 10, 0
    debug_method_msg db "Method: ", 0
    debug_path_msg db "Path: ", 0
    debug_header_msg db "Header: ", 0
    debug_value_msg db "Value: ", 0
    newline db 10, 0

    ; Error messages
    err_invalid_method db "Invalid HTTP method", 0
    err_path_too_long db "Request path too long", 0
    err_header_too_long db "Header too long", 0
    err_too_many_headers db "Too many headers", 0
    err_malformed db "Malformed request", 0

    ; HTTP method strings for comparison
    method_get db "GET", 0
    method_post db "POST", 0
    method_head db "HEAD", 0
    method_put db "PUT", 0
    method_delete db "DELETE", 0

    ; Buffer sizes
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

; Function to compare strings (null-terminated)
; Input: rdi = first string, rsi = second string
; Output: rax = 0 if equal, non-zero if different
str_compare:
    push rbp
    mov rbp, rsp
    
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    
    ; Check if we've reached the end of both strings
    test al, al
    jz .check_end
    test bl, bl
    jz .not_equal
    
    ; Compare characters
    cmp al, bl
    jne .not_equal
    
    ; Move to next character
    inc rdi
    inc rsi
    jmp .loop

.check_end:
    ; Check if second string also ended
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

; Parse HTTP request
; Input: rdi = client_fd, rsi = http_request struct pointer
; Output: rax = 0 on success, negative on error
parse_http_request:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Store parameters
    mov r12, rdi    ; client_fd
    mov r13, rsi    ; request struct

    ; Read request into buffer
    mov rdi, r12
    mov rsi, read_buffer
    mov rdx, BUFFER_SIZE
    call read
    cmp rax, 0
    jle .read_error

    ; Store read size
    mov r14, rax

    ; Parse method
    mov rdi, read_buffer
    mov rsi, r13
    call parse_method
    test rax, rax
    jnz .parse_error

    ; Parse path
    mov rdi, read_buffer
    add rdi, rax    ; Skip method
    mov rsi, r13
    call parse_path
    test rax, rax
    jnz .parse_error

    ; Parse headers
    xor r15, r15    ; Header count
.parse_headers_loop:
    cmp r15, 32     ; Max headers
    jge .too_many_headers

    ; Check for end of headers
    mov rdi, read_buffer
    add rdi, rax    ; Skip previous content
    cmp word [rdi], 0x0A0D  ; \r\n
    je .parsing_complete

    ; Parse header
    mov rsi, r13
    mov rdx, r15
    call parse_header
    test rax, rax
    jnz .parse_error

    inc r15
    jmp .parse_headers_loop

.parsing_complete:
    ; Store header count
    mov [r13 + 8], r15d  ; Offset for header_count in struct

    xor rax, rax    ; Return success
    jmp .cleanup

.read_error:
    mov rax, -3     ; Read error code
    jmp .cleanup

.parse_error:
    mov rax, -2     ; Parse error code
    jmp .cleanup

.too_many_headers:
    mov rax, -4     ; Too many headers error code

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Send HTTP response
; Input: rdi = client_fd, rsi = response buffer, rdx = response length
; Output: rax = bytes sent or negative on error
send_http_response:
    push rbp
    mov rbp, rsp
    
    ; Save registers
    push rbx
    push r12
    push r13
    
    ; Store parameters
    mov r12, rdi    ; client_fd
    mov r13, rsi    ; response buffer
    mov rbx, rdx    ; response length

    ; Call write syscall
    mov rdi, r12    ; fd
    mov rsi, r13    ; buffer
    mov rdx, rbx    ; length
    call write
    
    ; Check for write error
    cmp rax, 0
    jl .write_error
    
    ; Compare bytes written
    cmp rax, rbx
    jne .partial_write
    
    jmp .done

.write_error:
    mov rax, -4     ; Write error code
    jmp .cleanup

.partial_write:
    mov rax, -5     ; Partial write error code

.done:
.cleanup:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Helper functions
parse_method:
    push rbp
    mov rbp, rsp
    ; ... (method parsing implementation)
    ; Compare against known methods and set appropriate enum value
    pop rbp
    ret

parse_path:
    push rbp
    mov rbp, rsp
    ; ... (path parsing implementation)
    ; Ensure path starts with / and copy to struct
    pop rbp
    ret

parse_header:
    push rbp
    mov rbp, rsp
    ; ... (header parsing implementation)
    ; Parse "Name: Value" format and store in struct
    pop rbp
    ret

%ifdef DEBUG
section .data
    debug_fmt db "%s", 10, 0

section .text
debug_print:
    push rbp
    mov rbp, rsp
    
    ; Call printf
    mov rdi, debug_fmt
    mov rsi, rax    ; String to print
    xor rax, rax    ; No floating point
    call printf
    
    pop rbp
    ret
%endif