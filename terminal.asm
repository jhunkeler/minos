%ifndef _TERMINAL_ASM
%define _TERMINAL_ASM

T_BUFSZ equ 255					; maximum length of terminal input buffer

terminal:
	push bp
	mov bp, sp
	push ds
	push es

	mov ax, ds
	mov es, ax
	sub sp, T_BUFSZ				; reserve space for tokens

	cld

	.clear_buffer:
		xor ax, ax
		mov cx, T_BUFSZ / 2
		lea di, [bp - T_BUFSZ]
		mov dx, di
		repne stosb				; zero out token storage

		xor ax, ax
		mov cx, T_BUFSZ	/ 2		; counter is length of buffer
		mov di, t_buffer		; destination is buffer
		repne stosw			; zero buffer

	.do_prompt:
		xor cx, cx			; reset counter
						; this tracks keyboard presses
		mov al, ASCII_CR
		call putc			; write carriage return to console

		push t_msg_prompt		; address of prompt string
		push t_msg_prompt_fmt		; address of prompt format string
		call printf			; print prompt to console
		add sp, 2 * 2			; clean up stack

	mov di, t_buffer			; input destination is buffer
	.read_command:
		call kbd_read			; get input from user
		.update_buffer:
			cmp al, ASCII_CR
			je .flush_buffer	; if carriage return, flush buffer

			cmp cx, T_BUFSZ
			jge .read_command	; trap lines to long to fit in memory
						; we cannot continue until user hits return

			stosb			; write input character to buffer
			inc cx			; increment character count

			jmp .output		; output character (default)

		.flush_buffer:
			cmp [di-1], byte 0	; stosb above increments di.
						; (di - 1) is the previous input
			je .do_prompt		; if no input (null), start over

			mov al, ASCII_CR
			call putc		; print carriage return

			; ---- TEMPORARY ---
			; a command parser will be here eventually
			; TODO: write string tokenizer

			push ' '
			push dx
			push t_buffer
			call strtok
			add sp, 2 * 3

			push word ax
			call printh
			add sp, 2

			;push t_buffer		; push buffer string address
			;push t_buffer_fmt	; push buffer format string address
			;call printf		; write input to console
			;add sp, 2 * 2 		; clean up stack
			; --- END TEMPORARY ---

			jmp .clear_buffer	; zero out buffer / start over

	.output:
		call putc
		jmp .read_command		; print input to screen as we type

	jmp .do_prompt				; start over

	pop es
	pop ds
	mov sp, bp
	pop bp
	ret


; data
t_msg_prompt_fmt: db '%s', 0
t_msg_prompt: db '$ ', 0
t_buffer_fmt: db '%s', 0
t_buffer: times T_BUFSZ db 0

%endif
