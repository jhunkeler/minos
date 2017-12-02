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
	mov ax, [bp + 4]
	call putint
.return:
	pop ax
	mov sp, bp
	pop bp
	ret


printh:
	push bp
	mov bp, sp
	push ax

	mov ax, [bp + 4]    ; integer WORD
	call puthex

.return:
	pop ax
	mov sp, bp
	pop bp
	ret


puthex:
	push ax
	push bx
	push cx
	push dx

	; ax is integer to print
	ror ah, 4		; reverse hex value
	ror al, 4
	xchg ah, al

	mov cx, 04h		; count (leading zeros)
	.divide:
		mov bx, 10h		; set divisor

		xor dx, dx		; clear mod
		div bx			; divide by 16

		cmp dl, 10		; don't adjust values less than 10
		jl .decimal
		.alpha:
			sub dl, 10		; (remainder - 10) -> align with ascii (base 10)
			add dl, 'A'		; (remainder + 'A') -> ascii offset conversion
			jmp .write
		.decimal:
			or dl, 30h 		; remainder -> ascii
	.write:
		dec cx
		xchg ax, dx	   	; exchange registers to get ascii value
		call putc		; print value
		xchg ax, dx		; restore registers

		cmp al, 0		; loop if al != 0
		jne .divide

		cmp cx, 0
		jne .divide

.return:
	pop dx
	pop cx
	pop bx
	pop ax
	ret


putint:
	push bp
	mov bp, sp
	pusha

	mov cx, 05h		; count (+leading zeros)
	mov di, 00h		; inner loop count
	.divide:
		mov bx, 0Ah		; set divisor

		xor dx, dx		; clear mod
		div bx			; divide by 10
		or dl, 30h 		; remainder -> ascii

		dec cx
		inc di			; local stack counter
		push dx

		cmp al, 0		; loop if al != 0
		jne .divide

		cmp cx, 0		; no more zeros?
		jne .divide

	.write:
		pop ax			; pop first value of integer
		dec di			; decrement our loop counter
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

	mov di, bp		; save base pointer address
	push di

	mov bx, [bp + 4]	; format string address
	add bp, 6		; set base pointer to beginning of '...' args

	; count arguments
	std			; buffer direction 'up'
	mov cx, 0		; set counter
	mov si, bp		; source index is base pointer
	.count_args:
		lodsw		; load word at es:si
		add cx, 1	; increase arg count
		cmp ax, 0	; here we're looking for a "natural null terminator"
				; on the stack
		jne .count_args

	cld					; clear direction flag
	mov si, bx				; source index is format string
	.main_string:
		lodsb				; load byte in format string
						; BEGIN READING FORMAT STRING
		cmp al, '%'			; trigger parser on '%' symbol
		je .parse_fmt

		cmp al, 0			; if at end of format string
		je .finalize			; return

		call putc			; write character
						; when character is not a format specifier

		jmp .main_string		; repeat

		.parse_fmt:
			lodsb				; get next byte
			; switch(formatter)
							; [for example]
			cmp al, '%'			; '%%' - just print the character
			je .do_percent_escape

			cmp al, 'd'			; '%d' - process integer
			je .do_int

			cmp al, 'x'			; '%x' - process hexadecimal
			je .do_hex

			cmp al, 's'			; '%s' - process string
			je .do_string

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

			.do_hex:
				mov ax, [bp]
				call puthex
				jmp .parse_fmt_done

			.do_int:
				mov ax, [bp]
				call putint
				jmp .parse_fmt_done

			.do_string:
				mov ax, [bp]
				push ax
				call puts
				add sp, 2
				jmp .parse_fmt_done

			.do_default:
				; nothing found

	.parse_fmt_done:
		add bp, 2		; increment base pointer by one WORD
					; <<< these are our function arguments >>>
		jmp .main_string	; keep reading the format string

.finalize:
	mov bp, di			; restore original base pointer address.
					; this is pretty dangerous actually. if
					; a procedure modifies DI without restoring
					; it, we're doomed; we'll roll right off the
					; edge into oblivion.
	pop di
	mov sp, bp
	pop bp
	ret


%endif
