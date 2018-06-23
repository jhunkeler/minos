%ifndef _BUILTIN_EXIT_ASM
%define _BUILTIN_EXIT_ASM

builtin_exit:
	push .msg_fmt
	call printf
	add sp, 2 * 1

	mov [terminal_exit], byte 1

	ret
	.msg_fmt db 'exiting...\n', 0

%endif
