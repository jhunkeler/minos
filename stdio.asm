%ifndef _STDIO_ASM
%define _STDIO_ASM

%include "console.asm"

puts:
	; Write string buffer at cursor position
	push bp
	mov bp, sp
	pusha

	mov si, [bp + 4]	; address of string buffer
	mov bx, 0000h		;
	mov ah, 0eh		; BIOS - teletype

.loop:
	lodsb			; load byte at [si] into al
	or al, 0		; 0 | 0 = 0 (detect null terminator)
	je .end
	call putc		; write character
	jmp .loop
.end:
	popa
	mov sp, bp
	pop bp
	ret


printi:
	push bp
	mov bp, sp
	push ax
	push cx

	mov ax, [bp + 4]
	mov cx, 0
	push cx
	push word [bp + 4]    ; integer WORD
	call putint
	add sp, 2 * 2
.return:
	pop cx
	pop ax
	mov sp, bp
	pop bp
	ret


printh:
	push bp
	mov bp, sp
	push ax
	push cx

	mov cx, 0
	push cx
	push word [bp + 4]    ; integer WORD
	call puthex
	add sp, 2 * 2
.return:
	pop cx
	pop ax
	mov sp, bp
	pop bp
	ret


puthex:
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	push di

	xor di, di
	mov ax, [bp + 4]	; value to print
	mov cx, [bp + 6]	; padding count (+leading zeros)

	cmp cx, 0
	jg .divide
	inc cx

	.divide:
		mov bx, 10h		; set divisor

		xor dx, dx		; clear mod
		div bx			; divide by 16

		cmp dl, 10		; don't adjust values less than 10
		jl .decimal
		.alpha:
			sub dl, 10	; (remainder - 10) -> align with ascii (base 10)
			add dl, 'A'	; (remainder + 'A') -> ascii offset conversion
			jmp .collect
		.decimal:
			or dl, 30h	; remainder -> ascii

	.collect:
		push dx			; push ascii value onto stack
		inc di			; increment stack counter

		cmp ax, 0		; loop if al != 0
		jne .divide

		cmp di, cx		; only pad zeros if padding count is greater than
					; the number of elements pushed to the stack
		jge .write

	mov dx, 30h			; store padding byte (ascii zero)
	sub cx, di			; How many zeros will we pad?
	.padding:
		push dx			; push padding byte
		inc di			; increment stack counter
		dec cx			; decrement padding counter
		jne .padding		; loop until CX == 0

	.write:
		dec di			; decrement stack counter

		pop ax			; pop ascii value off stack
		call putc		; print value

		cmp di, 0
		jne .write
.return:
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret


putint:
	push bp
	mov bp, sp
	pusha

	mov ax, [bp + 4]	; value to print
	mov cx, [bp + 6]	; padding count (+leading zeros)
	mov di, 00h			; inner loop count

	.divide:
		mov bx, 0Ah		; set divisor

		xor dx, dx		; clear mod
		div bx			; divide by 10
		or dl, 30h		; remainder -> ascii

	.collect:
		push dx			; push ascii value onto stack
		inc di			; increment stack counter

		cmp al, 0		; loop if al != 0
		jne .divide

		cmp di, cx		; only pad zeros if padding count is greater than
					; the number of elements pushed to the stack
		jge .write

	mov dx, 30h			; store padding byte (ascii zero)
	sub cx, di			; How many zeros will we pad?
	.padding:
		push dx			; push padding byte
		inc di			; increment stack counter
		dec cx			; decrement padding counter
		jne .padding		; loop until CX == 0

	.write:
		pop ax			; pop first value of integer
		dec di			; decrement our stack counter
		call putc		; write character
		cmp di, 0		; done?
		jne .write
.return:
	popa

	mov sp, bp
	pop bp
	ret


printf:
	push bp
	mov bp, sp
	pusha

	mov si, [bp + 4]	; source index is format string address
	add bp, 6		; set base pointer to beginning of '...' args

	xor cx, cx		; initialize width modifier count

	cld					; clear direction flag
	.main_string:
		xor ax, ax
		lodsb				; load byte in format string
						; BEGIN READING FORMAT STRING

		cmp al, '\'			; trigger control code expansion
		je .parse_control

		cmp al, '%'			; trigger parser on '%' symbol
		je .parse_fmt

		cmp al, 0			; if we are at the end of format string
		je .return			; then we are done printing

		call putc			; write character
						; when character is not a format specifier

		jmp .main_string		; read until the end of the string

		.parse_control:
			lodsb				; get next byte

			cmp al, 'n'			; new line
			je .do_LF

			cmp al, 'r'			; carriage return
			je .do_CR

			jmp .do_default

			.do_LF:
				mov ax, ASCII_CR	; home the line
				call putc

				mov ax, ASCII_LF	; increment line
				call putc
				jmp .main_string

			.do_CR:
				mov ax, ASCII_CR	; home the line
				call putc
				jmp .main_string

		.parse_fmt:
			lodsb				; get next byte

			mov cx, ax			; store incoming byte into CX
			sub cx, 30h			; subtract '0' from CX
			cmp cx, 9			; is ascii number?
			jbe .do_width_modifier		; then, use CX as format width

			xor cx, cx			; else, clear format width counter

		.parse_fmt_post_width:
			cmp al, '%'			; '%%' - just print the character
			je .do_percent_escape

			cmp al, 'c'			; '%c' - process character
			je .do_char

			cmp al, 'd'			; '%d' - process signed int
			je .do_int

			cmp al, 'i'			; '%i' - process signed int
			je .do_int

			cmp al, 'u'			; '%u' - process unsigned int
			je .do_uint

			cmp al, 'x'			; '%x' - process hexadecimal
			je .do_hex

			cmp al, 's'			; '%s' - process string
			je .do_string

			cmp al, 'p'			; '%p' - process pointer
			je .do_pointer

			jmp .do_default			; Matched nothing, so handle it

			; ---REMEMBER---
			; Our base pointer has been shifted
			; ---------------------------------
			; fmt  = bp + 4
			; arg1 = bp + 6 [<- we are here]
			; arg2 = bp + 8
			; arg3 = bp + 10
			; ...  = bp + ??

			.do_percent_escape:
				mov ax, '%'
				call putc
				jmp .main_string

			.do_char:
				mov ax, [bp]
				call putc
				jmp .main_string

			.do_hex:
				mov ax, [bp]
				push cx
				push ax
				call puthex
				add sp, 2 * 2
				jmp .parse_fmt_done

			.do_int:
			.do_uint:
				mov ax, [bp]
				push cx
				push ax
				call putint
				add sp, 2 * 2
				jmp .parse_fmt_done

			.do_string:
				mov ax, [bp]
				push ax
				call puts
				add sp, 2
				jmp .parse_fmt_done

			.do_pointer:
				push cx
				push word [bp]
				call puthex
				add sp, 2 * 2
				jmp .parse_fmt_done

			.do_width_modifier:
				lodsb	; get next byte (hopefully a format char)
					; and jump back into format parser to finish
					; things up
				jmp .parse_fmt_post_width

			.do_default:
				; nothing found

	.parse_fmt_done:
		add bp, 2		; increment base pointer by one WORD
					; <<< these are our function arguments >>>
		jmp .main_string	; keep reading the format string

.return:
	popa				; restore all registers
	mov sp, bp
	pop bp
	ret

%endif
