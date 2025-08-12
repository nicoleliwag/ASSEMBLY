section .data 
 msg db 'Hello, World!', 0xA ; The
message with newline 
 len equ $ - msg ; Message length 

section .text 
global _start 

_start: 
; Write message to stdout 
mov eax, 4 ; sys_write 
mov ebx, 1 ; file descriptor 1 = stdout 
mov ecx, msg ; address of message 
mov edx, len ; length of message
int 0x80 ; call kernel

; Exit program 
mov eax, 1 ; sys_exit 
xor ebx, ebx ; exit code 0 
int 0x80
