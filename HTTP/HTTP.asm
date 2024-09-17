section .data
    STDIN equ 0
    STDOUT equ 1
    STDERR equ 2
    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_SOCKET equ 41
    SYS_BIND equ 49
    SYS_LISTEN equ 50
    SYS_ACCEPT equ 43
    SYS_CLOSE equ 3
    AF_INET equ 2
    SOCK_STREAM equ 1
    INADDR_ANY equ 0
    PORT equ 8080

    http_ok db 'HTTP/1.1 200 OK', 13, 10
            db 'Content-Type: text/plain', 13, 10
            db 'Content-Length: %d', 13, 10, 13, 10, 0
    http_ok_len equ $ - http_ok

    http_not_found db 'HTTP/1.1 404 Not Found', 13, 10
                   db 'Content-Type: text/plain', 13, 10
                   db 'Content-Length: 14', 13, 10, 13, 10
                   db 'Page not found', 13, 10, 0
    http_not_found_len equ $ - http_not_found

    space db ' ', 0
    get_str db 'GET', 0
    post_str db 'POST', 0
    debug_accept db 'Accepted connection', 10, 0
    debug_accept_len equ $ - debug_accept
    debug_parse db 'Parsing request', 10, 0
    debug_parse_len equ $ - debug_parse
    debug_close db 'Closed connection', 10, 0
    debug_close_len equ $ - debug_close

    root_path db '/', 0
    root_response db 'Welcome to the root', 13, 10, 0
    root_response_len equ $ - root_response

    about_path db '/about', 0
    about_response db 'This is the about page', 13, 10, 0
    about_response_len equ $ - about_response

    contact_path db '/contact', 0
    contact_response db 'This is the contact page', 13, 10, 0
    contact_response_len equ $ - contact_response

section .bss
    buffer resb 1024
    client_socket resd 1
    server_socket resd 1
    method resb 16
    path resb 256
    response_buffer resb 1024

section .text
global _start

_start:
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
   
    mov [server_socket], eax
    mov rdi, rax
    mov rax, SYS_BIND
    mov rsi, sockaddr
    mov rdx, 16
    syscall

    mov rax, SYS_LISTEN
    mov rdi, [server_socket]
    mov rsi, 5
    syscall

accept_loop:
    mov rax, SYS_ACCEPT
    mov rdi, [server_socket]
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov [client_socket], eax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_accept
    mov rdx, debug_accept_len
    syscall

    mov rax, SYS_READ
    mov rdi, [client_socket]
    mov rsi, buffer
    mov rdx, 1024
    syscall

    test rax, rax
    jle close_client

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_parse
    mov rdx, debug_parse_len
    syscall

    call parse_request
    mov rsi, method
    mov rdi, get_str
    call strcmp
    test rax, rax
    jz handle_get
    mov rsi, method
    mov rdi, post_str
    call strcmp
    test rax, rax
    jz handle_post
    jmp send_not_found

handle_get:
handle_post:
    mov rsi, path
    mov rdi, root_path
    call strcmp
    test rax, rax
    jz send_root_response

    mov rsi, path
    mov rdi, about_path
    call strcmp
    test rax, rax
    jz send_about_response

    mov rsi, path
    mov rdi, contact_path
    call strcmp
    test rax, rax
    jz send_contact_response

send_not_found:
    mov rax, SYS_WRITE
    mov rdi, [client_socket]
    mov rsi, http_not_found
    mov rdx, http_not_found_len
    syscall
    jmp close_client

send_root_response:
    mov rsi, root_response
    mov rdx, root_response_len
    jmp send_response

send_about_response:
    mov rsi, about_response
    mov rdx, about_response_len
    jmp send_response

send_contact_response:
    mov rsi, contact_response
    mov rdx, contact_response_len
    jmp send_response

send_response:
    push rsi
    push rdx
    
    mov rdi, response_buffer
    mov rsi, http_ok
    mov rdx, [rsp]
    call sprintf

    mov rax, SYS_WRITE
    mov rdi, [client_socket]
    mov rsi, response_buffer
    mov rdx, rax
    syscall

    pop rdx
    pop rsi

    mov rax, SYS_WRITE
    mov rdi, [client_socket]
    syscall

close_client:
    mov rax, SYS_CLOSE
    mov rdi, [client_socket]
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_close
    mov rdx, debug_close_len
    syscall

    jmp accept_loop

parse_request:
    mov rsi, buffer
    mov rdi, method
    call parse_until_space
    mov rdi, path
    call parse_until_space
    ret

parse_until_space:
    xor rcx, rcx
.loop:
    mov al, [rsi]
    cmp al, ' '
    je .done
    mov [rdi + rcx], al
    inc rsi
    inc rcx
    cmp rcx, 15
    jl .loop
.done:
    mov byte [rdi + rcx], 0
    inc rsi
    ret

strcmp:
    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    cmp al, [rdi + rcx]
    jne .not_equal
    test al, al
    jz .equal
    inc rcx
    jmp .loop
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret

sprintf:
    push rbx
    push rcx
    mov rbx, rdi
    mov rcx, rdx
.loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, '%'
    je .format
    mov [rbx], al
    inc rsi
    inc rbx
    jmp .loop
.format:
    inc rsi
    mov al, [rsi]
    cmp al, 'd'
    jne .loop
    push rsi
    mov rsi, rcx
    call int_to_str
    pop rsi
    inc rsi
    jmp .loop
.done:
    mov byte [rbx], 0
    mov rax, rbx
    sub rax, rdi
    pop rcx
    pop rbx
    ret

int_to_str:
    push rbx
    push rdx
    push rsi
    mov rbx, 10
    mov rax, rsi
    xor rcx, rcx
.divide_loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .divide_loop
.build_string:
    pop rdx
    add dl, '0'
    mov [rdi], dl
    inc rdi
    loop .build_string
    mov byte [rdi], 0
    pop rsi
    pop rdx
    pop rbx
    ret

section .data
    sockaddr:
        dw AF_INET
        dw ((PORT & 0xFF) << 8) | ((PORT & 0xFF00) >> 8)
        dd INADDR_ANY
        dq 0