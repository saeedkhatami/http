section .text
global parse_http_request
global send_http_response
global str_compare
global debug_log

; parse HTTP request
; p:
;   rdi - buffer pointer
;   rsi - method buffer pointer
;   rdx - path buffer pointer
; r:
;   rax - 0 on success, -1 on failure
parse_http_request:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi    ; buffer
    mov r13, rsi    ; method
    mov r14, rdx    ; path

    ; Parse method
    xor rcx, rcx    ; counter
.parse_method:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .method_done
    cmp al, 0
    je .parse_error
    mov [r13 + rcx], al
    inc rcx
    cmp rcx, 15     ; max method length
    jge .parse_error
    jmp .parse_method

.method_done:
    mov byte [r13 + rcx], 0
    inc r12
    add r12, rcx    ; move past space

    ; Parse path
    xor rcx, rcx
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
    cmp rcx, 255    ; max path length
    jge .parse_error
    jmp .parse_path

.path_done:
    mov byte [r14 + rcx], 0
    xor rax, rax    ; return success
    jmp .cleanup

.parse_error:
    mov rax, -1     ; return error

.cleanup:
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