int21:
	nop
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
