%ifndef _TERMINAL_ASM
%define _TERMINAL_ASM

T_BUFSZ equ 256					; maximum length of terminal input buffer

terminal:
	push bp
	mov bp, sp

	.clear_buffer:
		mov cx, T_BUFSZ			; counter is length of buffer
		mov bx, t_buffer		; get address of buffer
		mov di, bx			; destination is buffer
		.cl:
			mov [di], byte 0	; zero out
			inc di			; increment buffer address
			dec cx			; decrement counter
			jne .cl			; repeat until counter is 0

		mov di, bx			; reset destination to original address

	.do_prompt:
		mov cx, 0			; reset counter
						; this tracks keyboard presses
		mov al, CR
		call putc			; write carriage return to console

		push t_msg_prompt		; address of prompt string
		push t_msg_prompt_fmt		; address of prompt format string
		call printf			; print prompt to console
		add sp, 4			; clean up stack

	mov di, t_buffer			; input destination is buffer
	.read_command:
		call kbd_read			; get input from user
		.update_buffer:
			cmp al, CR
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

			mov al, CR
			call putc		; print carriage return

			; ---- TEMPORARY ---
			; A jump to a command parser occur here eventually
			; TODO: write string tokenizer

			push t_buffer		; push buffer string address
			push t_buffer_fmt	; push buffer format string address
			call printf		; write input to console
			add sp, 4		; clean up stack
			; --- END TEMPORARY ---

			jmp .clear_buffer	; zero out buffer / start over

	.output:
		call putc
		jmp .read_command		; print input to screen as we type

	jmp .do_prompt				; start over

	mov sp, bp
	pop bp
	ret

; data
t_msg_prompt_fmt: db '%s', 0
t_msg_prompt: db '$ ', 0
t_buffer_fmt: db '%s', 0
t_buffer: times T_BUFSZ db 0

%endif
