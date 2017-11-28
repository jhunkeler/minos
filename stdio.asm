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
	int 10h			; BIOS video service
	jmp .loop
.end:
	popa
	mov sp, bp
	pop bp
	ret

%endif
