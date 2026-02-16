;--------------------------------
; Assembly Program: Greedy Snake
; Author: Flink_Tp
; Date: 20251122
;================================
.386
UP equ 4800h
DOWN equ 5000h
LEFT equ 4B00h
RIGHT equ 4D00h


code segment use16
assume cs:code

snake_length dw 3
snake_dir dw 2 dup(1), 98 dup(0)
; 1(mov right) 2(mov left) 3(mov up) 4(mov down)
it_head dw 0
it_tail dw 4
head_x dw 41
head_y dw 12
tail_x dw 39
tail_y dw 12
table dw RIGHT, 1, 1, 0, LEFT, 2, -1, 0, UP, 3, 0, -1, DOWN, 4, 0, 1
current_dir dw 1
apple_x dw 0
apple_y dw 0
boundary_x dw 0, 80
boundary_y dw 0, 25
check_x dw 0
check_y dw 0
seed dw 8127h
temp_val dw 0
old_8h dw 0, 0
clock_count dw 6

generate_apple:
    mov ah, 0
    int 1Ah
regenerate:
    mov ax, dx
    mov dx, 0
    mov cx, 80
    div cx
    mov apple_x, dx
    mov check_x, dx
    mov dx, 0
    mov cx, 25
    div cx
    mov apple_y, dx
    mov check_y, dx
    call range_check
    cmp ax, 0
    je generate_OK
    mov ah, 0
    int 1Ah
    add dx, seed
    jmp regenerate
generate_OK:
    mov ax, 0B800h
    mov ds, ax
    mov al, '@'
    mov ah, 0E1h
    mov bx, apple_y
    imul bx, 80
    add bx, apple_x
    shl bx, 1
    mov ds:[bx], ax
    ret

;------------------------------------------
; input: check_x, check_y
; output: ax
; ax=0 OK
; ax=1 Gameover
; ax=2 Getapple
; Register_used: di, bp, ax, bx, dx, ds
;==========================================
range_check:
    mov ax, check_x
    cmp ax, cs:boundary_x[0]
    jl ck_over
    cmp ax, cs:boundary_x[2]
    jge ck_over
    mov ax, check_y
    cmp ax, cs:boundary_y[0]
    jl ck_over
    cmp ax, cs:boundary_y[2]
    jge ck_over
    mov di, tail_x
    mov bp, tail_y
    mov bx, it_head
ck_next:
    cmp bx, it_tail
    je ck_apple
    cmp di, check_x
    jne ck_condok
    cmp bp, check_y
    jne ck_condok
    jmp ck_over
ck_condok:
    mov si, snake_dir[bx]
    push bx
    call look_up_table
    add di, cs:table[bx+2]
    add bp, cs:table[bx+4]
    pop bx
    add bx, 2
    mov dx, 0
    mov ax, bx
    mov bx, 200
    div bx
    mov bx, dx
    jmp ck_next
ck_apple:
    mov ax, check_y
    imul ax, 80
    add ax, check_x
    shl ax, 1
    mov di, 0B800h
    mov ds, di
    mov bx, ax
    cmp byte ptr ds:[bx], '@'
    jne ck_OK
    mov ax, 2
    mov di, 0
    ret
ck_OK:
    mov ax, 0
    mov di, 0
    ret
ck_over:
    mov ax, 1
    mov di, 0
    ret

fill_screen:
    mov ax, 0B800h
    mov ds, ax
    mov bx, 0
    mov cx, 80*25
    mov al, ' '
    mov ah, 71h
fill_again:
    mov ds:[bx], ax
    add bx, 2
    dec cx
    jnz fill_again
    ret

init_snake:
    mov ax, 0B800h
    mov ds, ax
    mov bx, (12*80+39)*2
    mov al, '#'
    mov ah, 41h
    mov ds:[bx], ax
    add bx, 2
    mov al, '#'
    mov ah, 41h
    mov ds:[bx], ax
    add bx, 2
    mov al, '#'
    mov ah, 24h
    mov ds:[bx], ax
    ret

look_up_table:
    mov bx, 2
comp_next:
    cmp cs:table[bx], si
    je look_uped
    add bx, 8
    jmp comp_next
look_uped:
    ret

;--------------------------------------
; input: si(direction)
; output: snake move
; Register_used: ax, bx, cx, dx, si, ds, di
;======================================
mov_snake:
    mov di, 0
    mov cx, 0B800h
    mov ds, cx
    mov bx, it_tail
    mov cs:snake_dir[bx], si
    mov al, '#'
    mov ah, 41h
    mov bx, head_y
    imul bx, 80
    add bx, head_x
    shl bx, 1
    mov ds:[bx], ax
    call look_up_table
    mov dx, cs:table[bx+2]
    add head_x, dx
    mov dx, head_x
    mov check_x, dx
    mov dx, cs:table[bx+4]
    add head_y, dx
    mov dx, head_y
    mov check_y, dx
    mov temp_val, si
    call range_check
    cmp ax, 0
    je range_ok
    cmp ax, 1
    je exit
    inc snake_length
    mov di, 1
range_ok:
    mov al, '#'
    mov ah, 24h
    mov bx, head_y
    imul bx, 80
    add bx, head_x
    shl bx, 1
    mov ds:[bx], ax
    mov bx, it_head
    mov si, cs:snake_dir[bx]
    cmp di, 1
    je skip_tail_clear
    mov al, ' '
    mov ah, 71h
    mov bx, tail_y
    imul bx, 80
    add bx, tail_x
    shl bx, 1
    mov ds:[bx], ax
    add it_head, 2
    call look_up_table
    mov dx, cs:table[bx+2]
    add tail_x, dx
    mov dx, cs:table[bx+4]
    add tail_y, dx
skip_tail_clear:
    add it_tail, 2
    mov dx, 0
    mov ax, it_tail
    mov cx, 200
    div cx
    mov it_tail, dx
    mov dx, 0
    mov ax, it_head
    div cx
    mov it_head, dx
    cmp di, 1
    je redraw
    ret
redraw:
    call generate_apple
    ret

modify_int8h:
    mov ax, 3508h
    int 21h
    mov old_8h[0], bx
    mov old_8h[2], es
    cli
    mov ax, seg new_int8h
    mov ds, ax
    mov dx, offset new_int8h
    mov ax, 2508h
    int 21h
    sti
    ret

new_int8h:
    call dword ptr cs:old_8h
    pushf
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    dec clock_count
    jnz exit_newint_8h
    mov si, current_dir
    call mov_snake
    mov clock_count, 6
exit_newint_8h:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    popf
    iret

main:
    call modify_int8h
    mov ax, 0B800h
    mov ds, ax
    call fill_screen
    call init_snake
    call generate_apple
for_loop:
    mov ah, 1
    int 16h
    jz skip_input
    mov ah, 0
    int 16h
    mov bx, 0
search_next:
    cmp cs:table[bx], ax
    je ok_to_move
    add bx, 8
    cmp bx, 32
    jb search_next
    jmp exit
ok_to_move:
    mov ax, cs:table[bx+2]
    mov current_dir, ax
skip_input:
    jmp for_loop
exit:
    cli
    mov ax, old_8h[2]
    mov ds, ax
    mov dx, old_8h[0]
    mov ax, 2508h
    int 21h
    sti
    mov ah, 4Ch
    int 21h
code ends
end main