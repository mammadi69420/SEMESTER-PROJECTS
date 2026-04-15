[org 0x0100]

jmp start

msg1 db "Enter first number: $"
msg2 db 13, 10, "Enter operator (+, -, *, /): $"
msg3 db 13, 10, "Enter second number: $"
msg_res db 13, 10, "Result: $"
msg_err db 13, 10, "Invalid operator!$"
msg_div db 13, 10, "Cannot divide by zero!$"

num1 dw 0
num2 dw 0
op   db 0

start:
    ; Get first number
    mov dx, msg1
    mov ah, 09h
    int 21h
    call read_num
    mov [num1], ax

    ; Get operator
    mov dx, msg2
    mov ah, 09h
    int 21h
    call read_op
    mov [op], al

    ; Get second number
    mov dx, msg3
    mov ah, 09h
    int 21h
    call read_num
    mov [num2], ax

    ; Display Result string
    mov dx, msg_res
    mov ah, 09h
    int 21h

    ; Setup registers for calculation
    mov ax, [num1]
    mov bx, [num2]
    mov cl, [op]

    cmp cl, '+'
    je do_add
    cmp cl, '-'
    je do_sub
    cmp cl, '*'
    je do_mul
    cmp cl, '/'
    je do_div

    ; If it doesn't match, invalid operator
    mov dx, msg_err
    mov ah, 09h
    int 21h
    jmp exit_prog

do_add:
    add ax, bx
    call print_num
    jmp exit_prog

do_sub:
    cmp ax, bx
    jge pos_sub
    ; Result is negative, handle sign
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax
    sub bx, ax
    mov ax, bx
    call print_num
    jmp exit_prog
pos_sub:
    sub ax, bx
    call print_num
    jmp exit_prog

do_mul:
    mul bx
    call print_num
    jmp exit_prog

do_div:
    cmp bx, 0
    jne valid_div
    mov dx, msg_div
    mov ah, 09h
    int 21h
    jmp exit_prog
valid_div:
    xor dx, dx
    div bx
    call print_num

exit_prog:
    ; Print trailing newlines
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h

    ; Terminate program
    mov ax, 4c00h
    int 21h

; -------- Subroutines --------

read_num:
    ; Reads an unsigned number from input and returns it in AX
    push bx
    push cx
    push dx
    mov bx, 0
skip_ws_num:
    mov ah, 01h
    int 21h
    cmp al, 13                ; Carriage return
    je skip_ws_num
    cmp al, 10                ; Line feed
    je skip_ws_num
    cmp al, ' '               ; Space
    je skip_ws_num

    ; First valid char is in AL
    cmp al, '0'
    jl end_read_num
    cmp al, '9'
    jg end_read_num
    sub al, '0'
    mov ah, 0
    mov bx, ax

read_loop:
    mov ah, 01h
    int 21h
    cmp al, '0'
    jl end_read_num
    cmp al, '9'
    jg end_read_num
    sub al, '0'
    mov ah, 0
    mov cx, ax

    mov ax, bx
    mov dx, 10
    mul dx                    ; dx:ax = ax * 10
    add ax, cx                ; ax = ax + cx
    mov bx, ax
    jmp read_loop

end_read_num:
    mov ax, bx
    pop dx
    pop cx
    pop bx
    ret

read_op:
    ; Reads an operator and returns it in AL
skip_ws_op:
    mov ah, 01h
    int 21h
    cmp al, 13
    je skip_ws_op
    cmp al, 10
    je skip_ws_op
    cmp al, ' '
    je skip_ws_op
    ret

print_num:
    ; Prints the unsigned number in AX
    push ax
    push bx
    push cx
    push dx

    cmp ax, 0
    jne start_convert
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp end_print_num

start_convert:
    mov bx, 10
    mov cx, 0
div_loop:
    cmp ax, 0
    je print_loop
    mov dx, 0
    div bx
    push dx
    inc cx
    jmp div_loop

print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop

end_print_num:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
