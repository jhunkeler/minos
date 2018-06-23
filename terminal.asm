%ifndef _TERMINAL_ASM
%define _TERMINAL_ASM
%include "builtins.asm"


T_BUFSZ equ 255					; maximum length of terminal input buffer


terminal:
	push bp
	mov bp, sp

	mov byte [terminal_exit], 0

	mov ax, ds
	mov es, ax
	sub sp, 2				; variable for buffer start address
	sub sp, T_BUFSZ				; reserve space for tokens

	cld

	.clear_buffer:
		xor ax, ax
		mov cx, T_BUFSZ / 2
		lea di, [bp - T_BUFSZ]		; load buffer start address
		mov [bp - 2], di		; store start address for later
		repne stosb			; zero out token storage

		xor ax, ax
		mov cx, T_BUFSZ	/ 2		; counter is length of buffer
		mov di, t_buffer		; destination is buffer
		repne stosw			; zero buffer

	.do_prompt:
		xor cx, cx			; reset counter
						; this tracks keyboard presses
		mov al, ASCII_LF
		call putc			; write carriage return to console

		push t_msg_prompt		; address of prompt string
		push t_msg_prompt_fmt		; address of prompt format string
		call printf			; print prompt to console
		add sp, 2 * 2			; clean up stack

	mov di, t_buffer			; input destination is buffer
	.read_command:
		call kbd_read			; get input from user

		cmp al, ASCII_CR		; return pressed?
		jne .update_buffer
		mov al, ASCII_LF		; convert CR to LF
		mov byte [di], 0

		.update_buffer:
			cmp al, ASCII_LF
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
			je .clear_buffer	; if no input (null), start over

			mov al, ASCII_LF
			call putc		; print carriage return

			push ' '
			push word [bp - 2]	; token array address
			push t_buffer		; address of terminal input buffer
			call strtok		; tokenize
			add sp, 2 * 3

			push cx				; push token count
			push ax				; push token array
			call terminal_check_input	; parse terminal input
			add sp, 2 * 1

			cmp byte [terminal_exit], 0
			jne .return

			jmp .clear_buffer	; zero out buffer / start over

	.output:
		call putc
		jmp .read_command		; print input to screen as we type

	.return:
		add sp, 2
		mov sp, bp
		pop bp
		ret


terminal_check_input:
	%define .token_count [bp + 6]
	%define .input_len [bp - 2]
	%define .scan_count [bp - 4]
	%define .compare_count [bp - 6]
	%define .input_baseaddr [bp - 8]
	%define .builtins_count [bp - 10]

	push bp
	mov bp, sp
	sub sp, 2 * 5

	pusha

	mov bx, word [bp + 4]			; arg1 - Token array
	mov .input_baseaddr, bx			; store base address of tokenized string

	mov cx, 0				; Initialize scan counter
	mov .scan_count, cx			; store initial counter value

	mov di, t_builtins_str			; Load destination index with a
						; list of builtin command
	mov si, .input_baseaddr			; Load source index with the address
	mov si, [si]				; Load the string at token address

	push si
	call strlen
	pop si
	mov .input_len, ax			; identifiers (strings)

	mov cx, 0
	mov si, t_builtins_fn
	.count_builtins:
		cmp word [si], 0
		je .count_builtins_done
		add si, 2
		inc cx
		jmp .count_builtins

	.count_builtins_done:
		mov word .builtins_count, cx

	.scan_builtins:
		mov cx, .scan_count
		cmp cx, .builtins_count
		jge .scan_no_match


		mov si, .input_baseaddr		; Load source index with the address
		mov si, [si]			; Load the string at token address

		push di				; get the length of builtin string...
		call strlen			; strtok returns pointers to the
		pop di
						; beginning of a substring, so in order
						; to scan for matches, we need to know
						; how many bytes to compare ahead
						; of time.

		mov cx, .input_len
		cmp ax, cx
		jne .compare_prefail

		mov .compare_count, ax		; Store return value of strlen in counter
		xor ax, ax
		xor dx, dx
		xor cx, cx

		.compare:
			mov al, byte [si]	; Load byte from input string
			mov dl, byte [di]	; Load byte from builtin identifier string

			cmp al, dl		; Compare bytes
			jne .compare_fail	; bytes did not match, so try the next string

			dec word .compare_count	; decrement counter
			je .return		; if counter == 0; return

			inc si			; Increment input string offset
			inc di			; Increment builtin identifier string offset
			jmp .compare		; ... continue

		.compare_fail:
			inc word .scan_count		; Increment builtin identifier
							; string attempt count
			inc di
			add di, word .compare_count	; Load the offset of the next
							; builtin identifier
			jmp .scan_builtins		; Continue scanning

		.compare_prefail:
			inc word .scan_count
			inc ax				; adjust for null terminator
			add di, ax			; Load the offset of the next
							; builtin identifier
			jmp .scan_builtins


	.return:
		mov bx, t_builtins_fn		; Load address of function pointer array
		mov cx, word .scan_count	; Load offset count
		shl cx, 1			; Multiply offset count by 2 (next WORD)
		add bx, cx			; Add offset to address of function
						; pointer array

	.execute:
		; Call builtin command with arguments
		mov si, .input_baseaddr		; argv - tokenized input string
		mov cx, .token_count		; argc - token count

		add si, 2			; argv offset is next token
		dec cx				; argc minus one token

		pushf				; save flags
		pusha				; save registers

		push si
		push cx
		call word [bx]			; Execute builtin command
		add sp, 2 * 2

		popa				; restore registers
		popf				; restore flags

	.scan_no_match:
		popa
		add sp, 2 * 5
		mov sp, bp
		pop bp
		ret


; data
t_msg_prompt_fmt: db '%s', 0
t_msg_prompt: db '$ ', 0
t_buffer_fmt: db '%s', 0
t_buffer: times T_BUFSZ db 0
terminal_exit: db 0

%endif
