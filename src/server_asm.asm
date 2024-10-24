%include "server_constants.inc"
section .text
global parse_http_request
global send_http_response
global str_compare
global debug_log

; parse HTTP request
; p:
;   rdi - buffer pointer
;   rsi - request struct pointer
; r:
;   rax - 0 on success, -1 on failure
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
    xor rcx, rcx    ; counter
.parse_method:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .method_done
    cmp al, 0
    je .parse_error
    mov [r13 + rcx], al    ; store in request.method
    inc rcx
    cmp rcx, MAX_METHOD-1
    jge .parse_error
    jmp .parse_method

.method_done:
    mov byte [r13 + rcx], 0    ; null terminate
    inc r12
    add r12, rcx    ; move past space

    ; parse path
    xor rcx, rcx
    lea r14, [r13 + MAX_METHOD]    ; point to request.path
.parse_path:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .path_done
    cmp al, '?'     ; stop at query string
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