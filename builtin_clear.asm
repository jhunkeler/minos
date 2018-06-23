%ifndef _BUILTIN_CLEAR_ASM
%define _BUILTIN_CLEAR_ASM

builtin_clear:
	call cls		; clear console
	push 0000h		; home position 0x0
	call setcursor		; home cursor on console
	add sp, 2		; cleanup stack
	ret

%endif
