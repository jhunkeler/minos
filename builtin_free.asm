%ifndef _BUILTIN_FREE_ASM
%define _BUILTIN_FREE_ASM

builtin_free:
	push bp
	mov bp, sp

	mov cx, word [bp + 4]	; argc
	mov bx, word [bp + 6]	; argv

	;cmp cx, 0		; if no arguments, return
	;jbe .return

	mov ah, 88h		; get extended memory size
	int 15h
	mov dx, ax

	int 12h			; get conventional memory size
				; but it's pretty much bogus

	push dx
	push ax
	push .msg_fmt
	call printf
	add sp, 2 * 2
	add bx, 2

	.return:
		mov sp, bp
		pop bp
		ret
	.msg_fmt db 'Conventional memory: %dK\n'
		 db 'Extended memory: %dK', 0

%endif
