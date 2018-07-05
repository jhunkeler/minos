int21:
	cmp al, .fn_table_size
	jg .return

	push bx
	push di
	movsx bx, al
	mov di, .fn_table
	call [di+bx]
	pop di
	pop bx

	.return:
		iret

	.fn_table:
		dw memset
		dw memcpy
	.fn_table_size dw $-.fn_table
int22:
	nop
int20:
	pusha
	mov ax, cs
	mov ds, ax
	mov ax, 0b800h
	mov es, ax

	mov bp, 0000h
	mov word [es:bp+79*2], 17h << 8 | 'B'
	popa
	iret
