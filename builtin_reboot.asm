%ifndef _BUILTIN_REBOOT_ASM
%define	_BUILTIN_REBOOT_ASM

builtin_reboot:
	mov bx, 3		; number of seconds
	.countdown:
		push bx
		push .msg_reboot_count
		call printf
		add sp, 2 * 2

		mov ah, 86h
		mov cx, 0fh
		mov dx, 4240h
		int 15h

		dec bx
		jne .countdown

	push .msg_reboot
	call printf
	add sp, 2 * 1

	jmp 0FFFFh:0000h	; issue reboot
	.msg_reboot_count db 'rebooting in %d seconds...\r', 0
	.msg_reboot db '\nreboot...\n', 0
	; no return, and the stack is irrelevant here

%endif
