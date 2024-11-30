%include "server_constants.inc"
%define body_offset MAX_METHOD + MAX_PATH + MAX_VERSION + 4
%define body_length_offset MAX_METHOD + MAX_PATH + MAX_VERSION + 12

section .data
method_get db "GET", 0
method_head db "HEAD", 0
method_post db "POST", 0
method_put db "PUT", 0
method_delete db "DELETE", 0
method_connect db "CONNECT", 0
method_options db "OPTIONS", 0
method_trace db "TRACE", 0
method_patch db "PATCH", 0

extern malloc
extern find_content_length
extern find_body_start

section .text
    global parse_http_request
    global send_http_response
    global str_compare
    global debug_log
    global get_method_type

get_method_type:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rdi        ; input method string

    ; Compare with GET
    mov rdi, rbx
    mov rsi, method_get
    call str_compare
    test eax, eax
    jz .is_get

    ; Compare with HEAD
    mov rdi, rbx
    mov rsi, method_head
    call str_compare
    test eax, eax
    jz .is_head

    ; Compare with POST
    mov rdi, rbx
    mov rsi, method_post
    call str_compare
    test eax, eax
    jz .is_post

    ; Compare with PUT
    mov rdi, rbx
    mov rsi, method_put
    call str_compare
    test eax, eax
    jz .is_put

    ; Compare with DELETE
    mov rdi, rbx
    mov rsi, method_delete
    call str_compare
    test eax, eax
    jz .is_delete

    ; Compare with CONNECT
    mov rdi, rbx
    mov rsi, method_connect
    call str_compare
    test eax, eax
    jz .is_connect

    ; Compare with OPTIONS
    mov rdi, rbx
    mov rsi, method_options
    call str_compare
    test eax, eax
    jz .is_options

    ; Compare with TRACE
    mov rdi, rbx
    mov rsi, method_trace
    call str_compare
    test eax, eax
    jz .is_trace

    ; Compare with PATCH
    mov rdi, rbx
    mov rsi, method_patch
    call str_compare
    test eax, eax
    jz .is_patch

    ; Unknown method
    mov eax, 0
    jmp .cleanup

.is_get:
    mov eax, 1
    jmp .cleanup

.is_head:
    mov eax, 2
    jmp .cleanup

.is_post:
    mov eax, 3
    jmp .cleanup

.is_put:
    mov eax, 4
    jmp .cleanup

.is_delete:
    mov eax, 5
    jmp .cleanup

.is_connect:
    mov eax, 6
    jmp .cleanup

.is_options:
    mov eax, 7
    jmp .cleanup

.is_trace:
    mov eax, 8
    jmp .cleanup

.is_patch:
    mov eax, 9
    jmp .cleanup

.cleanup:
    pop rbx
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

    mov r12, rdi    ; buffer
    mov r13, rsi    ; request struct

    ; Parse method
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
    
    ; Get method type
    push rcx
    mov rdi, r13    ; method string
    call get_method_type
    mov [r13 + MAX_METHOD - 4], eax    ; store method_type
    pop rcx
    
    ; Skip extra spaces after method
    inc r12
    add r12, rcx
.skip_method_spaces:
    mov al, [r12]
    cmp al, ' '
    jne .parse_path_start
    inc r12
    jmp .skip_method_spaces

.parse_path_start:
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
    
    ; Skip spaces after path
.skip_path_spaces:
    mov al, [r12]
    cmp al, ' '
    jne .parse_version_start
    inc r12
    jmp .skip_path_spaces

.parse_version_start:
    ; parse HTTP version
    xor rcx, rcx
    lea r14, [r13 + MAX_METHOD + MAX_PATH]
.parse_version:
    mov al, [r12 + rcx]
    cmp al, 13    ; CR
    je .check_version_lf
    cmp al, 0
    je .parse_error
    mov [r14 + rcx], al
    inc rcx
    cmp rcx, MAX_VERSION-1
    jge .parse_error
    jmp .parse_version

.check_version_lf:
    mov byte [r14 + rcx], 0    ; Null terminate version
    inc r12
    add r12, rcx    ; Move past version
    mov al, [r12]
    cmp al, 10    ; Check for LF after CR
    jne .parse_error
    inc r12        ; Skip LF

    ; parse headers
    lea r14, [r13 + MAX_METHOD + MAX_PATH + MAX_VERSION]    ; headers array
    xor r15, r15    ; header count

.parse_headers:
    mov al, [r12]
    cmp al, 13    ; CR (end of headers)
    je .check_headers_end
    
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
    add r12, rcx
    mov al, [r12]
    cmp al, 13    ; Expect CR
    jne .parse_error
    inc r12
    mov al, [r12]
    cmp al, 10    ; Expect LF
    jne .parse_error
    inc r12
    
    inc r15    ; increment header count
    lea r14, [r14 + MAX_HEADER_VALUE]    ; next header
    cmp r15, MAX_HEADERS
    jge .parse_error
    jmp .parse_headers

.check_headers_end:
    inc r12        ; Skip CR
    mov al, [r12]
    cmp al, 10    ; Check for LF
    jne .parse_error
    inc r12        ; Skip LF

    mov [r13 + MAX_METHOD + MAX_PATH + MAX_VERSION - 4], r15d    ; store header count

    ; Parse body if present
    jmp .parse_body

.parse_body:
    ; Check if there's a Content-Length header
    mov rdi, r12        ; current buffer position
    call find_content_length
    test rax, rax
    jz .success        ; No body to parse - we're done

    ; Store the content length
    mov [r13 + body_length_offset], rax
    
    ; Allocate memory for body
    push rax            ; save content length
    mov rdi, rax        ; length to allocate
    call malloc wrt ..plt
    test rax, rax
    pop rcx             ; restore content length to rcx
    jz .parse_error     ; malloc failed
    
    ; Store body pointer
    mov [r13 + body_offset], rax
    
    ; Copy body content
    mov rdi, rax        ; destination (allocated memory)
    mov rsi, r12        ; source (current buffer position)
    rep movsb           ; copy rcx bytes from rsi to rdi
    
    jmp .success

.parse_error:
    mov rax, -1
    jmp .cleanup

.success:
    xor rax, rax

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