%ifndef _BUILTIN_EXIT_ASM
%define _BUILTIN_EXIT_ASM

builtin_exit:
	push bp
	mov bp, sp

	push .msg_fmt
	call printf
	add sp, 2 * 1

	add sp, 2	; cleanup previous call address

	jmp terminal
	.msg_fmt db 'exiting...\n', 0

%endif
