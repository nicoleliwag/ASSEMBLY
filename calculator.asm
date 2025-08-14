section .data
    prompt1     db "Enter first number (0-99): ", 0
    prompt1len  equ $ - prompt1 - 1    ; exclude null terminator
    prompt2     db "Enter second number (0-99): ", 0
    prompt2len  equ $ - prompt2 - 1
    prompt_op   db "Enter operation (+ - * /): ", 0
    prompt_oplen equ $ - prompt_op - 1
    prompt_res  db "Result: ", 0
    prompt_reslen equ $ - prompt_res - 1
    prompt_again db "Calculate again? (y/n): ", 0
    prompt_againlen equ $ - prompt_again - 1
    newline     db 10
    error_msg   db "Error: Division by zero!", 10, 0
    error_len   equ $ - error_msg - 1
    error_op    db "Error: Invalid operation! Use +, -, *, or /", 10, 0
    error_op_len equ $ - error_op - 1
    error_num   db "Error: Invalid number! Enter 0-99 only", 10, 0
    error_num_len equ $ - error_num - 1

section .bss
    num1     resb 3     ; two digits + newline
    num2     resb 3
    op       resb 2     ; operator + newline
    outbuf   resb 10    ; larger buffer for results
    answer   resb 2     ; for y/n answer

section .text
    global _start

_start:
main_loop:
    ; Clear all input buffers at start of each loop
    mov ecx, num1
    mov byte [ecx], 0
    mov byte [ecx+1], 0
    mov byte [ecx+2], 0
    
    mov ecx, num2
    mov byte [ecx], 0
    mov byte [ecx+1], 0
    mov byte [ecx+2], 0
    
    mov ecx, op
    mov byte [ecx], 0
    mov byte [ecx+1], 0

    ; Read first number
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt1
    mov edx, prompt1len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num1
    mov edx, 3
    int 0x80

    ; Clear num1 buffer - ensure proper null termination
    mov ecx, num1
    add ecx, 2
    mov byte [ecx], 0

    ; Read second number
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt2
    mov edx, prompt2len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num2
    mov edx, 3
    int 0x80

    ; Clear num2 buffer - ensure proper null termination
    mov ecx, num2
    add ecx, 2
    mov byte [ecx], 0

    ; Read operation
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_op
    mov edx, prompt_oplen
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, op
    mov edx, 2
    int 0x80

    ; Clear op buffer - ensure proper null termination
    mov byte [op+1], 0

    ; Convert num1 ASCII to integer
    mov al, [num1]
    ; Check if first character is a valid digit
    cmp al, '0'
    jl invalid_num1
    cmp al, '9'
    jg invalid_num1
    sub al, '0'
    mov bl, [num1+1]
    cmp bl, 10          ; check for newline
    je one_digit1
    cmp bl, '0'         ; check if it's a digit
    jl invalid_num1
    cmp bl, '9'
    jg invalid_num1
    sub bl, '0'
    mov cl, al          ; save first digit
    mov al, 10
    mul cl              ; multiply first digit by 10
    add al, bl          ; add second digit
one_digit1:
    movzx esi, al       ; store first number in esi

    ; Convert num2 ASCII to integer
    mov al, [num2]
    ; Check if first character is a valid digit
    cmp al, '0'
    jl invalid_num2
    cmp al, '9'
    jg invalid_num2
    sub al, '0'
    mov bl, [num2+1]
    cmp bl, 10          ; check for newline
    je one_digit2
    cmp bl, '0'         ; check if it's a digit
    jl invalid_num2
    cmp bl, '9'
    jg invalid_num2
    sub bl, '0'
    mov cl, al          ; save first digit
    mov al, 10
    mul cl              ; multiply first digit by 10
    add al, bl          ; add second digit
one_digit2:
    movzx edi, al       ; store second number in edi

    ; Determine operation and compute
    mov cl, [op]
    cmp cl, '+'
    je do_add
    cmp cl, '-'
    je do_sub
    cmp cl, '*'
    je do_mul
    cmp cl, '/'
    je do_div
    jmp invalid_operation

do_add:
    mov eax, esi
    add eax, edi
    jmp convert

do_sub:
    mov eax, esi
    sub eax, edi
    jmp check_negative

do_mul:
    mov eax, esi
    imul eax, edi
    jmp convert

do_div:
    cmp edi, 0
    je div_by_zero
    mov eax, esi
    xor edx, edx
    idiv edi
    jmp convert

div_by_zero:
    ; Print error message
    mov eax, 4
    mov ebx, 1
    mov ecx, error_msg
    mov edx, error_len
    int 0x80
    jmp ask_again

invalid_num1:
invalid_num2:
    ; Print invalid number error
    mov eax, 4
    mov ebx, 1
    mov ecx, error_num
    mov edx, error_num_len
    int 0x80
    jmp ask_again

invalid_operation:
    ; Print invalid operation error
    mov eax, 4
    mov ebx, 1
    mov ecx, error_op
    mov edx, error_op_len
    int 0x80
    jmp ask_again

check_negative:
    test eax, eax       ; check if result is negative
    jns convert         ; if not negative, proceed to convert
    
    ; Handle negative result
    neg eax             ; make it positive
    push eax            ; save the positive value
    
    ; Print "Result: -"
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_res
    mov edx, prompt_reslen
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_sign
    mov edx, 1
    int 0x80
    
    pop eax             ; restore the positive value
    jmp convert_no_prompt

minus_sign db '-'

; Convert integer result (in EAX) to ASCII in outbuf
convert:
    ; Print "Result: " first
    push eax            ; save result
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_res
    mov edx, prompt_reslen
    int 0x80
    pop eax             ; restore result

convert_no_prompt:
    mov ecx, outbuf + 9  ; point to end of buffer
    mov byte [ecx], 0    ; null terminate
    mov ebx, 10

convert_loop:
    dec ecx
    xor edx, edx
    div ebx
    add dl, '0'
    mov [ecx], dl
    test eax, eax
    jnz convert_loop

    ; Calculate string length
    mov edx, outbuf + 9
    sub edx, ecx        ; length = end - start

    ; Print the number string
    mov eax, 4
    mov ebx, 1
    ; ecx already points to start of string
    int 0x80

    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

ask_again:
    ; Clear answer buffer
    mov byte [answer], 0
    mov byte [answer+1], 0
    
    ; Ask if user wants to calculate again
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_again
    mov edx, prompt_againlen
    int 0x80

    ; Read user's answer
    mov eax, 3
    mov ebx, 0
    mov ecx, answer
    mov edx, 2
    int 0x80

    ; Check if user wants to continue
    mov al, [answer]
    cmp al, 'y'
    je main_loop
    cmp al, 'Y'
    je main_loop

done:
    mov eax, 1
    xor ebx, ebx
    int 0x80
