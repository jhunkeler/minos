%ifndef _STDIO_ASM
%define _STDIO_ASM

%include "console.asm"

puts:
	; Write string buffer at cursor position
	push bp
	mov bp, sp
	pusha

	mov si, [bp + 4]	; address of string buffer
	mov bx, 0000h		;
	mov ah, 0eh		; BIOS - teletype

.loop:
	lodsb			; load byte at [si] into al
	or al, 0		; 0 | 0 = 0 (detect null terminator)
	je .end
	call putc
	jmp .loop
.end:
	popa
	mov sp, bp
	pop bp
	ret


printi:
    push bp
    mov bp, sp

    mov ax, [bp + 4]    ; integer WORD
    mov cx, 0          ; counter
    cmp ax, 0
    je .write_no_pop

.divide:
    xor dx, dx
    mov di, 10          ; divisor
    div di

    push dx
    inc cx
    cmp ax, 0
    jne .divide

    jmp .write

.write_no_pop:
    or al, 30h
    call putc
    jmp .return

.write:
    pop ax

    or al, 30h
    call putc
    dec cx
    jne .write

.return:
    mov sp, bp
    pop bp
    ret

printh:
    push bp
    mov bp, sp

    mov ax, [bp + 4]    ; integer WORD
    mov cx, 0          ; counter
    cmp ax, 0
    je .write_no_pop

.divide:
    xor dx, dx
    mov di, 16          ; divisor
    div di

    push dx
    inc cx
    cmp ax, 0
    jne .divide

    jmp .write

.write_no_pop:
    or al, 30h
    call putc
    jmp .return

.write:
    pop ax
    cmp al, 10
    jge .alpha

    or al, 30h
    jmp .decimal

.alpha:
    sub al, 10
    add al, 'A'

.decimal:
    call putc
    dec cx
    jne .write

.return:
    mov sp, bp
    pop bp
    ret
%endif
