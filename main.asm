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

STDIN equ 0
STDOUT equ 1
STDERR equ 2

macro read fd, buffer, count
{
    mov rax, sys_read
    mov rdi, fd
    mov rsi, buffer
    mov rdx, count
    syscall
}

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
    write STDOUT, socket_info, socket_info_len
    socket AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl .err
    mov qword [sockfd], rax

    mov word	[servaddr.sin_family], AF_INET
    mov word	[servaddr.sin_port], 36895 ;; port: 8080
    mov dword   [servaddr.sin_addr], INADOR_ANY

    write STDOUT, bind_info, bind_info_len
    bind [sockfd], servaddr, sizeof_servaddr
    cmp rax, 0
    jl .err

    write STDOUT, listen_info, listen_info_len
    listen [sockfd], CONN_LEN
    cmp rax, 0
    jl .err

    write STDOUT, waiting_info, waiting_info_len
    accept [sockfd], cliaddr, sizeof_cliaddr
    mov qword [connfd], rax

    write qword [connfd], conn_stab, conn_stab_len 
.loop:
    ; let client write
    write qword [connfd], msg_wr, msg_wr_len
    read qword [connfd], msg, 10

    ; let server know
    write STDOUT, msg, 10

    ; let server write
    write STDOUT, msg_wr, msg_wr_len
    read STDIN, msg, 10

    ; let client know
    write qword [connfd], msg, 10

    jmp .loop

    write STDOUT, ok, ok_len
    close [connfd]
    close [sockfd]
    exit 0

.err:
    write STDOUT, err_msg,err_msg_len 
    close [connfd]
    close [sockfd]
    exit 0

segment readable writable
sockfd dq -1
connfd dq -1

struc sockaddr_in
{
    .sin_family dw 0
    .sin_port dw 0
    .sin_addr dd 0
    .sin_zero dq 0
}
servaddr sockaddr_in
sizeof_servaddr = $ - servaddr.sin_family

cliaddr sockaddr_in
sizeof_cliaddr dd sizeof_servaddr

; msg

msg db 0

socket_info db "[INFO]: Creating socket.", 10
socket_info_len = $ - socket_info

bind_info db "[INFO]: Binding socket.", 10
bind_info_len = $ - bind_info

listen_info db "[INFO]: Server is listening.", 10
listen_info_len = $ - listen_info

waiting_info db "[INFO]: Server is waiting.", 10
waiting_info_len = $ - waiting_info

ok db "[INFO]: OK!", 10
ok_len = $ - ok

err_msg db "[INFO]: ERROR!", 10
err_msg_len = $ - err_msg

conn_stab db "[INFO]: Connection has been established.", 10
conn_stab_len = $ - conn_stab

msg_wr db "MSG ==> "
msg_wr_len = $ - msg_wr
