%include "server_constants.inc"
section .text
global parse_http_request
global send_http_response
global str_compare
global debug_log

parse_http_request:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi    ; buffer
    mov r13, rsi    ; request struct

    ; parse method
    xor rcx, rcx
.parse_method:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .method_done
    cmp al, 0
    je .parse_error
    mov [r13 + rcx], al
    inc rcx
    cmp rcx, MAX_METHOD-1
    jge .parse_error
    jmp .parse_method

.method_done:
    mov byte [r13 + rcx], 0
    inc r12
    add r12, rcx

    ; parse path
    xor rcx, rcx
    lea r14, [r13 + MAX_METHOD]
.parse_path:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .path_done
    cmp al, '?'
    je .path_done
    cmp al, 0
    je .parse_error
    mov [r14 + rcx], al
    inc rcx
    cmp rcx, MAX_PATH-1
    jge .parse_error
    jmp .parse_path

.path_done:
    mov byte [r14 + rcx], 0
    add r12, rcx
    inc r12    ; skip space

    ; parse HTTP version
    xor rcx, rcx
    lea r14, [r13 + MAX_METHOD + MAX_PATH]
.parse_version:
    mov al, [r12 + rcx]
    cmp al, 13    ; CR
    je .version_done
    cmp al, 10    ; LF
    je .version_done
    cmp al, 0
    je .parse_error
    mov [r14 + rcx], al
    inc rcx
    cmp rcx, MAX_VERSION-1
    jge .parse_error
    jmp .parse_version

.version_done:
    mov byte [r14 + rcx], 0

    ; parse headers
    lea r14, [r13 + MAX_METHOD + MAX_PATH + MAX_VERSION]    ; headers array
    xor r15, r15    ; header count

.parse_headers:
    add r12, rcx
    inc r12    ; skip CR
    mov al, [r12]
    cmp al, 10    ; LF
    jne .parse_error
    inc r12    ; skip LF
    
    mov al, [r12]
    cmp al, 13    ; CR (end of headers)
    je .headers_done
    
    ; parse header name
    xor rcx, rcx
.parse_header_name:
    mov al, [r12 + rcx]
    cmp al, ':'
    je .header_name_done
    cmp al, 0
    je .parse_error
    mov [r14 + rcx], al
    inc rcx
    cmp rcx, MAX_HEADER_NAME-1
    jge .parse_error
    jmp .parse_header_name

.header_name_done:
    mov byte [r14 + rcx], 0
    add r12, rcx
    inc r12    ; skip :
    
    ; skip whitespace
.skip_header_ws:
    mov al, [r12]
    cmp al, ' '
    jne .parse_header_value
    inc r12
    jmp .skip_header_ws

    ; parse header value
.parse_header_value:
    xor rcx, rcx
    lea r14, [r14 + MAX_HEADER_NAME]
.parse_header_value_loop:
    mov al, [r12 + rcx]
    cmp al, 13    ; CR
    je .header_value_done
    cmp al, 0
    je .parse_error
    mov [r14 + rcx], al
    inc rcx
    cmp rcx, MAX_HEADER_VALUE-1
    jge .parse_error
    jmp .parse_header_value_loop

.header_value_done:
    mov byte [r14 + rcx], 0
    inc r15    ; increment header count
    lea r14, [r14 + MAX_HEADER_VALUE]    ; next header
    cmp r15, MAX_HEADERS
    jge .parse_error
    jmp .parse_headers

.headers_done:
    mov [r13 + MAX_METHOD + MAX_PATH + MAX_VERSION - 4], r15d    ; store header count
    
    ; success
    xor rax, rax
    jmp .cleanup

.parse_error:
    mov rax, -1

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; send HTTP response
; p:
;   rdi - file descriptor
;   rsi - data pointer
;   rdx - length
send_http_response:
    push rbp
    mov rbp, rsp
    
    mov rax, 1      ; sys_write
    syscall
    
    pop rbp
    ret

; string comparison
; p:
;   rdi - first string pointer
;   rsi - second string pointer
; r:
;   rax - 0 if equal, non-zero if different
str_compare:
    push rbp
    mov rbp, rsp

.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rdi
    inc rsi
    jmp .loop

.not_equal:
    mov rax, 1
    jmp .done

.equal:
    xor rax, rax

.done:
    pop rbp
    ret

; debug logging
; p:
;   rdi - message pointer
;   rsi - length
debug_log:
    push rbp
    mov rbp, rsp

    push rdi
    push rsi
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    pop rdx             ; length
    pop rsi             ; message
    syscall

    pop rbp
    ret

section .data
    newline db 10

section .bss
    temp_buffer resb 4096