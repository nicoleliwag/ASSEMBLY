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
    error_answer db "Error: Please enter 'y' for yes or 'n' for no", 10, 0
    error_answer_len equ $ - error_answer - 1

section .bss
    num1     resb 10    ; larger buffer for input
    num2     resb 10
    op       resb 10    ; larger buffer for operator
    outbuf   resb 20    ; larger buffer for results with decimals
    answer   resb 10    ; larger buffer for y/n answer
    temp_buf resb 10    ; temporary buffer for input cleaning

section .text
    global _start

_start:
main_loop:
    ; Clear all input buffers at start of each loop
    call clear_all_buffers

    ; Read first number
get_first_number:
    call clear_all_buffers
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt1
    mov edx, prompt1len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num1
    mov edx, 10
    int 0x80

    ; Clean the input by removing newline
    call clean_input_num1

    ; Validate and convert num1 immediately
    mov al, [num1]
    cmp al, 0           ; check for empty input
    je invalid_num1_immediate
    ; Check if first character is a valid digit
    cmp al, '0'
    jl invalid_num1_immediate
    cmp al, '9'
    jg invalid_num1_immediate
    sub al, '0'
    mov bl, [num1+1]
    cmp bl, 0           ; check for end of string
    je store_first_num
    cmp bl, '0'         ; check if it's a digit
    jl invalid_num1_immediate
    cmp bl, '9'
    jg invalid_num1_immediate
    ; Check if there's a third character (invalid for 0-99)
    cmp byte [num1+2], 0
    jne invalid_num1_immediate
    sub bl, '0'
    mov cl, al          ; save first digit
    mov al, 10
    mul cl              ; multiply first digit by 10
    add al, bl          ; add second digit
store_first_num:
    movzx esi, al       ; store first number in esi

    ; Read second number
get_second_number:
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt2
    mov edx, prompt2len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num2
    mov edx, 10
    int 0x80

    ; Clean the input by removing newline
    call clean_input_num2

    ; Validate and convert num2 immediately
    mov al, [num2]
    cmp al, 0           ; check for empty input
    je invalid_num2_immediate
    ; Check if first character is a valid digit
    cmp al, '0'
    jl invalid_num2_immediate
    cmp al, '9'
    jg invalid_num2_immediate
    sub al, '0'
    mov bl, [num2+1]
    cmp bl, 0           ; check for end of string
    je store_second_num
    cmp bl, '0'         ; check if it's a digit
    jl invalid_num2_immediate
    cmp bl, '9'
    jg invalid_num2_immediate
    ; Check if there's a third character (invalid for 0-99)
    cmp byte [num2+2], 0
    jne invalid_num2_immediate
    sub bl, '0'
    mov cl, al          ; save first digit
    mov al, 10
    mul cl              ; multiply first digit by 10
    add al, bl          ; add second digit
store_second_num:
    movzx edi, al       ; store second number in edi

    ; Read operation
get_operation:
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_op
    mov edx, prompt_oplen
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, op
    mov edx, 10
    int 0x80

    ; Clean the input by removing newline
    call clean_input_op

    ; Validate operation immediately
    mov cl, [op]
    cmp cl, 0           ; check for empty input
    je invalid_operation_immediate
    cmp cl, '+'
    je do_add
    cmp cl, '-'
    je do_sub
    cmp cl, '*'
    je do_mul
    cmp cl, '/'
    je do_div
    jmp invalid_operation_immediate

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
    
    ; For division, we'll calculate with 2 decimal places
    ; Multiply dividend by 100 to get 2 decimal places
    mov ebx, 100
    mul ebx         ; eax = num1 * 100
    xor edx, edx
    idiv edi        ; eax = (num1 * 100) / num2
    
    ; Now eax contains the result * 100
    ; We need to format this as XX.XX
    jmp convert_decimal

div_by_zero:
    ; Print error message
    mov eax, 4
    mov ebx, 1
    mov ecx, error_msg
    mov edx, error_len
    int 0x80
    jmp ask_again

invalid_num1_immediate:
    ; Print invalid number error for first number
    mov eax, 4
    mov ebx, 1
    mov ecx, error_num
    mov edx, error_num_len
    int 0x80
    jmp get_first_number

invalid_num2_immediate:
    ; Print invalid number error for second number
    mov eax, 4
    mov ebx, 1
    mov ecx, error_num
    mov edx, error_num_len
    int 0x80
    jmp get_second_number

invalid_operation_immediate:
    ; Print invalid operation error
    mov eax, 4
    mov ebx, 1
    mov ecx, error_op
    mov edx, error_op_len
    int 0x80
    jmp get_operation

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

; Convert decimal result (result * 100) to XX.XX format
convert_decimal:
    ; Print "Result: " first
    push eax            ; save result
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_res
    mov edx, prompt_reslen
    int 0x80
    pop eax             ; restore result

convert_decimal_no_prompt:
    ; eax contains result * 100
    ; We need to separate integer and decimal parts
    push eax            ; save original result
    
    ; Get integer part (divide by 100)
    xor edx, edx
    mov ebx, 100
    div ebx             ; eax = integer part, edx = remainder (decimal part * 100)
    
    ; Convert integer part to string
    push edx            ; save decimal part
    mov ecx, outbuf + 15  ; point to middle of buffer
    mov byte [ecx], 0     ; null terminate
    mov ebx, 10

convert_int_loop:
    dec ecx
    xor edx, edx
    div ebx
    add dl, '0'
    mov [ecx], dl
    test eax, eax
    jnz convert_int_loop

    ; Print integer part
    mov edx, outbuf + 15
    sub edx, ecx        ; length = end - start
    mov eax, 4
    mov ebx, 1
    int 0x80

    ; Print decimal point
    mov eax, 4
    mov ebx, 1
    mov ecx, decimal_point
    mov edx, 1
    int 0x80

    ; Convert decimal part (2 digits)
    pop eax             ; restore decimal part
    mov ecx, outbuf + 18
    mov byte [ecx], 0   ; null terminate
    mov ebx, 10
    
    ; Second decimal digit
    dec ecx
    xor edx, edx
    div ebx
    add dl, '0'
    mov [ecx], dl
    
    ; First decimal digit
    dec ecx
    add al, '0'
    mov [ecx], al

    ; Print decimal part (always 2 digits)
    mov eax, 4
    mov ebx, 1
    mov edx, 2          ; always print exactly 2 digits
    int 0x80

    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    jmp ask_again

decimal_point db '.'

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
get_answer:    
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
    mov edx, 10
    int 0x80

    ; Clean the input by removing newline
    call clean_input_answer

    ; Validate answer immediately
    mov al, [answer]
    cmp al, 0           ; check for empty input
    je invalid_answer_msg
    cmp al, 'y'
    je main_loop
    cmp al, 'Y'
    je main_loop
    cmp al, 'n'
    je done
    cmp al, 'N'
    je done
    
invalid_answer_msg:
    ; Invalid answer - show error and ask again
    mov eax, 4
    mov ebx, 1
    mov ecx, error_answer
    mov edx, error_answer_len
    int 0x80
    jmp get_answer

done:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; Helper functions to clear buffers and clean input
clear_all_buffers:
    push eax
    push ecx
    ; Clear num1
    mov ecx, num1
    mov eax, 0
    mov [ecx], eax
    mov [ecx+4], eax
    mov [ecx+8], eax
    ; Clear num2  
    mov ecx, num2
    mov [ecx], eax
    mov [ecx+4], eax
    mov [ecx+8], eax
    ; Clear op
    mov ecx, op
    mov [ecx], eax
    mov [ecx+4], eax
    mov [ecx+8], eax
    ; Clear answer
    mov ecx, answer
    mov [ecx], eax
    mov [ecx+4], eax
    mov [ecx+8], eax
    pop ecx
    pop eax
    ret

clean_input_num1:
    push eax
    push ecx
    mov ecx, num1
    call remove_newline
    pop ecx
    pop eax
    ret

clean_input_num2:
    push eax
    push ecx
    mov ecx, num2
    call remove_newline
    pop ecx
    pop eax
    ret

clean_input_op:
    push eax
    push ecx
    mov ecx, op
    call remove_newline
    pop ecx
    pop eax
    ret

clean_input_answer:
    push eax
    push ecx
    mov ecx, answer
    call remove_newline
    pop ecx
    pop eax
    ret

remove_newline:
    push eax
    push ebx
clean_loop:
    mov al, [ecx]
    cmp al, 0
    je clean_done
    cmp al, 10          ; newline character
    je replace_newline
    cmp al, 13          ; carriage return
    je replace_newline
    inc ecx
    jmp clean_loop
replace_newline:
    mov byte [ecx], 0   ; replace with null terminator
    jmp clean_done
clean_done:
    pop ebx
    pop eax
    rety
