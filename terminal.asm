%ifndef _TERMINAL_ASM
%define _TERMINAL_ASM

MAXBUF equ 254

terminal:
	push bp
	mov bp, sp
	;sub sp, MAXBUF		; allocate large string buffer
	
	.clear_buffer:
		mov cx, MAXBUF
		mov bx, t_buffer
		mov di, bx
		.cl:
			mov [di], byte 0
			inc di
			dec cx
			jne .cl
		mov di, bx

	.do_prompt:	
		mov cx, 0
		mov al, CR
		call putc

		push t_msg_prompt
		push t_msg_prompt_fmt
		call printf
		add sp, 4
	
	mov di, t_buffer	
	.read_command:
		call kbd_read
		.update_buffer:
			cmp al, CR
			je .dump_buffer
			stosb
			inc cx

			jmp .output

		.dump_buffer:
			cmp [di-1], byte 0
			je .do_prompt

			mov al, CR
			call putc

			push t_buffer			; push onto stack
			push t_buffer_fmt
			call printf		; write out string
			add sp, 4
	
			jmp .clear_buffer
			
	.output:
		call putc
		jmp .read_command

	jmp .do_prompt

	mov sp, bp
	pop bp
	ret

; data
t_msg_prompt_fmt: db '%s', 0
t_msg_prompt: db '$ ', 0
t_buffer_fmt: db '%s', 0
t_buffer: times MAXBUF db 0

%endif
