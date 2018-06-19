%ifndef _BUILTIN_ECHO_ASM
%define _BUILTIN_ECHO_ASM

builtin_echo:
	push bp
	mov bp, sp

	mov bx, word [bp + 4]
	add bx, 2
	push word [bx]
	push .msg_fmt
	call printf
	add sp, 2 * 2

	mov sp, bp
	pop bp
	ret
	.msg_fmt db '%s\n', 0

%endif
