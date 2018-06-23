%ifndef _BUILTIN_VIDEO_MODE_ASM
%define _BUILTIN_VIDEO_MODE_ASM

builtin_video_mode:
	push bp
	mov bp, sp

	mov cx, [bp + 4]	; Load argc
	mov bx, [bp + 6]	; Load argv

	cmp cx, 1		; Not enough args?
	jl .no_args		; ... die
	jmp .main

	.no_args:
		push .error_arg
		call printf
		add sp, 2 * 1
		jmp .return

	; main program

	.main:
		mov bx, [bx]	; Load first element in argv array
		mov si, bx	; First element is source index

		push bx		; Get length of element
		call strlen
		add sp, 2
		mov cx, ax	; Store length
		mov bx, 0


		mov ax, 0
		mov dx, 0
		.chars:
			lodsb		; Load character from ES:SI
			cmp ax, '9'	; If value is greater than '9' it's likely hex, so
					; adjust AX to compensate
			jg .ishex

			sub ax, '0'	; Otherwise, the value is base-10
			jmp .nosub

		.tolower:
			sub ax, 20h
		.ishex:
			cmp ax, 'a'
			jge .tolower	; If we recieved a lowercase letter, convert it
					; to uppercase, then continue

			cmp ax, 'F'	; Is this a valid hexadecimal value? (0 ~ F)
			jg .invalid_input

			sub ax, 'A'	; Convert character to BCD
			add ax, 10

		.nosub:
			shl dx, 4	; Shift current BCD value 4-bits left
			or dx, ax	; Tack on the latest value
			dec cx		; Decrement counter
			jne .chars	; continue until no characters remain


		cmp dx, 13h		; Is the final value a valid video mode?
		jg .invalid_mode


		mov al, dl		; BIOS video services only operate on a byte value
					; ... oh well.

		mov ah, 00h
		int 10h			; Set video mode

	.return:
		mov sp, bp
		pop bp
		ret

	.invalid_input:
		push ax
		push .error_hex
		call printf
		add sp, 2 * 2
		jmp .return

	.invalid_mode:
		push dx
		push .error_mode
		call printf
		add sp, 2 * 2
		jmp .return

	.error_arg: db 'error: no graphics mode requested. (0..13)\n', 0
	.error_hex: db 'error: "%c" is an invalid hexadecimal value (0..F)\n', 0
	.error_mode: db 'error: %2x is an invalid video mode (0..13)\n', 0

%endif
