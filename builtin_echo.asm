%ifndef _BUILTIN_ECHO_ASM
%define _BUILTIN_ECHO_ASM

builtin_echo:
	push bp
	mov bp, sp

	mov cx, word [bp + 4]	; argc
	mov bx, word [bp + 6]	; argv

	cmp cx, 0		; if no arguments, return
	jbe .return

	.output:		; print argv
		push word [bx]
		push .msg_fmt
		call printf
		add sp, 2 * 2
		add bx, 2
		dec cx
		jne .output

	.return:
		mov sp, bp
		pop bp
		ret
	.msg_fmt db '%s ', 0

%endif
