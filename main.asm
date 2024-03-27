format ELF64 executable

sys_read equ 0
sys_write equ 1
sys_close equ 3
sys_exit equ 60
sys_socket equ 41
sys_bind equ 49
sys_accept equ 43
sys_listen equ 50

AF_INET equ 2
SOCK_STREAM equ 1
INADOR_ANY equ 0
CONN_LEN equ 5

STDOUT equ 1
STDERR equ 2

macro write fd, buffer, count
{
    mov rax, sys_write
    mov rdi, fd
    mov rsi, buffer
    mov rdx, count
    syscall
}

macro exit code
{
    mov rax, sys_exit
    mov rdi, code
    syscall
}

;; int socket(int domain, int type, int protocol);
macro socket domain, type, protocol
{
    mov rax, sys_socket
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    syscall
}
;; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
macro bind sockfd, addr, addrlen
{
    mov rax, sys_bind
    mov rdi, sockfd
    mov rsi, addr
    mov rdx, addrlen
    syscall
}

;; int listen(int sockfd, int backlog);
macro listen sockfd, backlog
{
    mov rax, sys_listen
    mov rdi, sockfd
    mov rsi, backlog
    syscall
}

;; int accept(int sockfd, const struct sockaddr *addr, socklen_t *addrlen);
macro accept sockfd, addr, addrlen
{
    mov rax, sys_accept
    mov rdi, sockfd
    mov rsi, addr
    mov rdx, addrlen
    syscall
}

; int close(int fd);
macro close fd
{
    mov rax, sys_close
    mov rdi, fd
    syscall
}

segment readable executable
entry main

main:
    socket AF_INET, SOCK_STREAM, 0
    test rax, rax
    jl .err
    mov qword [sockfd], rax
    write STDOUT, sock_ok, sock_ok_len

    mov word	[servaddr.sin_family], AF_INET
    mov word	[servaddr.sin_port], 36895 ;; port: 8080
    mov dword   [servaddr.sin_addr], INADOR_ANY

    bind [sockfd], servaddr, sizeof_sockaddr_in
    test rax, rax
    jl .err
    write STDOUT, bind_ok, bind_ok_len

    listen [sockfd], CONN_LEN
    test rax, rax
    jl .err
    write STDOUT, listening_msg, listening_msg_len

    accept [sockfd], cliaddr, sizeof_cliaddr

    close rax
    close [sockfd]
    exit 0

.err:
    write STDERR, err_msg, err_msg_len
    exit 0

segment readable writable
sockfd dq 0
connfd dq 0
struc sockaddr_in
{
    .sin_family dw 0
    .sin_port dw 0
    .sin_addr dd 0
    .sin_zero dq 0
}
servaddr sockaddr_in
sizeof_sockaddr_in = $ - servaddr

cliaddr sockaddr_in
sizeof_cliaddr = $ - cliaddr

;; err msg
err_msg db "ERROR", 10
err_msg_len = $ - err_msg

;; ok sock msg
sock_ok db "socket created, ok.", 10
sock_ok_len = $ - sock_ok

;; ok bind msg
bind_ok db "socket binded, ok.", 10
bind_ok_len = $ - bind_ok

; ok listen msg
listening_msg db "server listening...", 10
listening_msg_len = $ - listening_msg
