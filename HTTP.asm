section .data
    STDIN equ 0
    STDOUT equ 1
    STDERR equ 2
    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_OPEN equ 2
    SYS_CLOSE equ 3
    SYS_SOCKET equ 41
    SYS_ACCEPT equ 43
    SYS_BIND equ 49
    SYS_LISTEN equ 50
    SYS_FCNTL equ 72
    SYS_EPOLL_CREATE equ 213
    SYS_EPOLL_CTL equ 233
    SYS_EPOLL_WAIT equ 232

    AF_INET equ 2
    SOCK_STREAM equ 1
    INADDR_ANY equ 0
    PORT equ 8080

    EPOLLIN equ 1
    EPOLLOUT equ 4
    EPOLLET equ (1 << 31)
    EPOLL_CTL_ADD equ 1
    EPOLL_CTL_DEL equ 2
    O_NONBLOCK equ 2048
    F_GETFL equ 3
    F_SETFL equ 4
    MAX_EVENTS equ 10

    http_ok db 'HTTP/1.1 200 OK', 13, 10
            db 'Server: Assembly HTTP Server', 13, 10
            db 'Content-Type: text/plain', 13, 10
            db 'Content-Length: %d', 13, 10
            db 'Connection: close', 13, 10, 13, 10, 0
    http_ok_len equ $ - http_ok

    http_not_found db 'HTTP/1.1 404 Not Found', 13, 10
                   db 'Server: Assembly HTTP Server', 13, 10
                   db 'Content-Type: text/plain', 13, 10
                   db 'Content-Length: 14', 13, 10
                   db 'Connection: close', 13, 10, 13, 10
                   db 'Page not found', 13, 10, 0
    http_not_found_len equ $ - http_not_found

    http_method_not_allowed db 'HTTP/1.1 405 Method Not Allowed', 13, 10
                            db 'Server: Assembly HTTP Server', 13, 10
                            db 'Content-Type: text/plain', 13, 10
                            db 'Content-Length: 18', 13, 10
                            db 'Connection: close', 13, 10, 13, 10
                            db 'Method not allowed', 13, 10, 0
    http_method_not_allowed_len equ $ - http_method_not_allowed

    space db ' ', 0
    newline db 13, 10, 0
    colon db ':', 0
    get_str db 'GET', 0
    post_str db 'POST', 0
    put_str db 'PUT', 0
    delete_str db 'DELETE', 0


    debug_socket db 'Socket created', 10, 0
    debug_socket_len equ $ - debug_socket
    debug_bind db 'Socket bound', 10, 0
    debug_bind_len equ $ - debug_bind
    debug_listen db 'Listening for connections', 10, 0
    debug_listen_len equ $ - debug_listen
    debug_accept db 'Accepted connection', 10, 0
    debug_accept_len equ $ - debug_accept
    debug_read db 'Read from client', 10, 0
    debug_read_len equ $ - debug_read
    debug_write db 'Wrote to client', 10, 0
    debug_write_len equ $ - debug_write
    error_socket db 'Error creating socket', 10, 0
    error_socket_len equ $ - error_socket
    error_bind db 'Error binding socket', 10, 0
    error_bind_len equ $ - error_bind
    error_listen db 'Error listening on socket', 10, 0
    error_listen_len equ $ - error_listen
    debug_parse db 'Parsing request', 10, 0
    debug_parse_len equ $ - debug_parse
    debug_close db 'Closed connection', 10, 0
    debug_close_len equ $ - debug_close
    debug_epoll_create db 'Created epoll instance', 10, 0
    debug_epoll_create_len equ $ - debug_epoll_create
    debug_epoll_add db 'Added fd to epoll', 10, 0
    debug_epoll_add_len equ $ - debug_epoll_add
    debug_epoll_wait db 'Epoll wait returned', 10, 0
    debug_epoll_wait_len equ $ - debug_epoll_wait
    error_epoll_create db 'Error creating epoll instance', 10, 0
    error_epoll_create_len equ $ - error_epoll_create
    error_epoll_ctl db 'Error adding fd to epoll', 10, 0
    error_epoll_ctl_len equ $ - error_epoll_ctl
    debug_event_loop db 'Entering event loop', 10, 0
    debug_event_loop_len equ $ - debug_event_loop
    debug_start db 'Program started', 10, 0
    debug_start_len equ $ - debug_start
    error_write db 'Error writing to stdout', 10, 0
    error_write_len equ $ - error_write

    root_path db '/', 0
    root_response db 'Welcome to the root!', 13, 10, 0
    root_response_len equ $ - root_response

    about_path db '/about', 0
    about_response db 'This is the about page.', 13, 10, 0
    about_response_len equ $ - about_response

    contact_path db '/contact', 0
    contact_response db 'This is the contact page', 13, 10, 0
    contact_response_len equ $ - contact_response

    post_response db 'POST request received', 13, 10, 0
    post_response_len equ $ - post_response

    put_response db 'PUT request received', 13, 10, 0
    put_response_len equ $ - put_response

    delete_response db 'DELETE request received', 13, 10, 0
    delete_response_len equ $ - delete_response

    struc epoll_event
        .events: resd 1
        .data:   resq 1
    endstruc

section .bss
    buffer resb 4096
    client_socket resd 1
    server_socket resd 1
    epoll_fd resd 1
    events resb epoll_event_size * MAX_EVENTS
    method resb 16
    path resb 256
    response_buffer resb 4096
    headers resb 2048

section .text
global _start

_start:
_start:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_start
    mov rdx, debug_start_len
    syscall

    cmp rax, -1
    je write_error

    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
   
    test rax, rax
    js .socket_error
    
    mov [server_socket], eax
    
    mov rdi, debug_socket
    mov rsi, debug_socket_len
    call debug_print

    mov rdi, rax
    mov rax, SYS_BIND
    mov rsi, sockaddr
    mov rdx, 16
    syscall

    test rax, rax
    jnz .bind_error

    mov rdi, debug_bind
    mov rsi, debug_bind_len
    call debug_print

    mov rax, SYS_LISTEN
    mov rdi, [server_socket]
    mov rsi, 5
    syscall

    test rax, rax
    jnz .listen_error

    mov rdi, debug_listen
    mov rsi, debug_listen_len
    call debug_print

    mov rax, SYS_EPOLL_CREATE
    mov rdi, 1
    syscall

    test rax, rax
    js .epoll_create_error

    mov [epoll_fd], eax

    mov rdi, debug_epoll_create
    mov rsi, debug_epoll_create_len
    call debug_print

    mov rdi, [epoll_fd]
    mov rsi, EPOLL_CTL_ADD
    mov rdx, [server_socket]
    lea rcx, [events]
    mov dword [rcx + epoll_event.events], EPOLLIN
    mov [rcx + epoll_event.data], rdx
    mov rax, SYS_EPOLL_CTL
    syscall

    test rax, rax
    jnz .epoll_ctl_error

    mov rdi, debug_epoll_add
    mov rsi, debug_epoll_add_len
    call debug_print

    jmp event_loop

.socket_error:
    mov rdi, error_socket
    mov rsi, error_socket_len
    call debug_print
    jmp exit_program

.bind_error:
    mov rdi, error_bind
    mov rsi, error_bind_len
    call debug_print
    jmp exit_program

.listen_error:
    mov rdi, error_listen
    mov rsi, error_listen_len
    call debug_print
    jmp exit_program

.epoll_create_error:
    mov rdi, error_epoll_create
    mov rsi, error_epoll_create_len
    call debug_print
    jmp exit_program

.epoll_ctl_error:
    mov rdi, error_epoll_ctl
    mov rsi, error_epoll_ctl_len
    call debug_print
    jmp exit_program

event_loop:
    mov rdi, debug_event_loop
    mov rsi, debug_event_loop_len
    call debug_print
    mov rax, SYS_EPOLL_WAIT
    mov rdi, [epoll_fd]
    mov rsi, events
    mov rdx, MAX_EVENTS
    mov r10, -1
    syscall
    
    test rax, rax
    jle event_loop
    
    mov r12, rax
    xor r13, r13

process_events:
    cmp r13, r12
    jge event_loop

    mov r14, r13
    imul r14, epoll_event_size
    add r14, events
    mov edi, [r14 + epoll_event.data]
    cmp edi, [server_socket]
    je accept_connection
    
    call handle_client

    inc r13
    jmp process_events

accept_connection:
    mov rax, SYS_ACCEPT
    mov rdi, [server_socket]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    
    test rax, rax
    jl .accept_error
    
    mov rdi, rax
    push rax
    call make_socket_non_blocking
    pop rax
    
    mov rdi, [epoll_fd]
    mov rsi, EPOLL_CTL_ADD
    mov rdx, rax
    lea rcx, [events + epoll_event_size]
    mov dword [rcx + epoll_event.events], EPOLLIN | EPOLLET
    mov [rcx + epoll_event.data], rax
    mov rax, SYS_EPOLL_CTL
    syscall
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_epoll_add
    mov rdx, debug_epoll_add_len
    syscall

.accept_error:
    inc r13
    jmp process_events

handle_client:
    push rdi

    mov rax, SYS_READ
    mov rsi, buffer
    mov rdx, 4096
    syscall

    test rax, rax
    jle .close_client
    
    push rax
    mov rdi, debug_read
    mov rsi, debug_read_len
    call debug_print
    pop rax

    call parse_request
    
    mov rsi, method
    mov rdi, get_str
    call strcmp
    test rax, rax
    jz handle_get_request

    mov rsi, method
    mov rdi, post_str
    call strcmp
    test rax, rax
    jz handle_post_request

    mov rsi, method
    mov rdi, put_str
    call strcmp
    test rax, rax
    jz handle_put_request

    mov rsi, method
    mov rdi, delete_str
    call strcmp
    test rax, rax
    jz handle_delete_request

    call send_method_not_allowed
    jmp .close_client

.close_client:
    pop rdi
    call close_client
    ret

handle_get_request:
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
    
    mov rax, SYS_WRITE
    mov rsi, http_not_found
    mov rdx, http_not_found_len
    syscall
    jmp close_client

handle_post_request:
    mov rsi, post_response
    mov rdx, post_response_len
    jmp send_response

handle_put_request:
    mov rsi, put_response
    mov rdx, put_response_len
    jmp send_response

handle_delete_request:
    mov rsi, delete_response
    mov rdx, delete_response_len
    jmp send_response

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
    mov rsi, response_buffer
    mov rdx, rax  
    syscall

    push rax
    mov rdi, debug_write
    mov rsi, debug_write_len
    call debug_print
    pop rax

    pop rdx
    pop rsi

    mov rax, SYS_WRITE
    syscall

    push rax
    mov rdi, debug_write
    mov rsi, debug_write_len
    call debug_print
    pop rax

    jmp close_client

send_method_not_allowed:
    mov rax, SYS_WRITE
    mov rsi, http_method_not_allowed
    mov rdx, http_method_not_allowed_len
    syscall
    jmp close_client

close_client:
    mov rax, SYS_CLOSE
    syscall

    mov rsi, EPOLL_CTL_DEL
    mov rax, SYS_EPOLL_CTL
    mov rdi, [epoll_fd]
    xor rcx, rcx
    syscall
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, debug_close
    mov rdx, debug_close_len
    syscall

    ret

make_socket_non_blocking:
    push rdi
    mov rax, SYS_FCNTL
    mov rsi, F_GETFL
    xor rdx, rdx
    syscall

    mov rdx, rax
    or rdx, O_NONBLOCK
    pop rdi
    push rdi
    mov rax, SYS_FCNTL
    mov rsi, F_SETFL
    syscall

    pop rdi
    ret

parse_request:
    mov rsi, buffer
    mov rdi, method
    call parse_until_space
    mov rdi, path
    call parse_until_space
    
    call parse_until_newline

    mov rdi, headers
.parse_headers_loop:
    mov al, [rsi]
    cmp al, 13
    je .headers_end
    call parse_header
    jmp .parse_headers_loop

.headers_end:
    add rsi, 2
    ret

parse_header:
    push rsi
    push rdi

.header_name_end:
    mov byte [rdi], 0
    inc rdi
    inc rsi

.parse_header_name:
    mov al, [rsi]
    cmp al, ':'
    je .header_name_end
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .parse_header_name  

debug_print:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, rsi
    mov rsi, rdi
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
    
.skip_spaces:
    mov al, [rsi]
    cmp al, ' '
    jne .parse_header_value
    inc rsi
    jmp .skip_spaces

.parse_header_value:
    call parse_until_newline
    
    pop rdi
    pop rsi
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
    cmp rcx, 255
    jl .loop
.done:
    mov byte [rdi + rcx], 0
    inc rsi
    ret

parse_until_newline:
    xor rcx, rcx
.loop:
    mov al, [rsi]
    cmp al, 13
    je .done
    mov [rdi + rcx], al
    inc rsi
    inc rcx
    cmp rcx, 1023
    jl .loop
.done:
    mov byte [rdi + rcx], 0
    add rsi, 2
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

write_error:
    mov rax, SYS_WRITE
    mov rdi, STDERR
    mov rsi, error_write
    mov rdx, error_write_len
    syscall
    jmp exit_program

exit_program:
    mov rax, 60
    mov rdi, 1
    syscall

section .data
    sockaddr:
        dw AF_INET
        dw ((PORT & 0xFF) << 8) | ((PORT & 0xFF00) >> 8)
        dd INADDR_ANY
        dq 0