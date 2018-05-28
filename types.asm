%ifndef _TYPES_ASM
%define _TYPES_ASM

isalpha:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	cmp ax, 40h
	jl .no
	cmp ax, 7Ah		; 40h..7Ah (A..z, ascii)
	jg .no

	.yes:
		clc		; clear carry (is alpha)
		jmp .return
	.no:
		stc		; set carry (not alpha)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


isalnum:
	push bp
	mov bp, sp
	push ax

	clc			; clear carry
	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	push ax
	call isalpha
	jc .no
	call isdigit
	jc .no

	.yes:
		clc		; clear carry (is alphanumeric)
		jmp .return
	.no:
		stc		; set carry (not alphanumeric)
	.return:
		add sp, 2
		pop ax
		mov sp, bp
		pop bp
		ret


isascii:
	push bp
	mov bp, sp
	push ax

	clc			; clear carry
	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	cmp ax, 00h
	jl .no
	cmp ax, 80h		; 00h..80h (standard ascii)
	jg .no

	.yes:
		clc		; clear carry (is ascii)
		jmp .return
	.no:
		stc		; set carry (not ascii)
	.return:
		add sp, 2
		pop ax
		mov sp, bp
		pop bp
		ret


isblank:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	cmp ax, 09h		; 09h ('\t', ascii)
	je .yes
	cmp ax, 0Ah		; 0Ah ('\n', ascii)
	je .yes
	cmp ax, 0Dh		; 0Dh ('\r', ascii)
	je .yes
	cmp ax, 20h		; 20h (' ', ascii)
	je .yes

	jmp .no			; no match

	.yes:
		clc		; clear carry (is space)
		jmp .return
	.no:
		stc		; set carry (not space)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


iscntrl:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	cmp ax, 00h
	jl .no
	cmp ax, 1fh		; 00h..1fh (ascii control codes)
	jg .no

	.yes:
		clc		; clear carry (is a control code)
		jmp .return
	.no:
		stc		; set carry (not a control code)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


isdigit:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	sub ax, '0'
	cmp ax, 0
	jl .no
	cmp ax, 9		; 30h..39h (0..9, ascii)
	jg .no

	.yes:
		clc		; clear carry (is a digit)
		jmp .return
	.no:
		stc		; set carry (not a digit)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret

isgraph:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	cmp ax, 21h
	jl .no
	cmp ax, 0FFh		; 21h..0FFh (graphical chars, except space)
	jg .no

	.yes:
		clc		; clear carry (is graphical)
		jmp .return
	.no:
		stc		; set carry (not graphical)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


islower:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	cmp ax, 'a'
	jl .no
	cmp ax, 'z'		; 61h..7Ah (a..z, ascii)
	jg .no

	.yes:
		clc		; clear carry (is lowercase)
		jmp .return
	.no:
		stc		; set carry (not lowercase)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


isprint:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test
	cmp ax, 20h
	jl .no
	cmp ax, 0FFh		; 20h..0FFh (graphical chars, including space)
	jg .no

	.yes:
		clc		; clear carry (is graphical)
		jmp .return
	.no:
		stc		; set carry (not graphical)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


ispunct:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	push ax
	call isalnum		; should not be alphanumeric
	jc .no

	call isblank		; should not be blank
	jc .no

	cmp ax, 21h		; 21h ('!', ascii)
	jl .no
	cmp ax, 40h		; 40h ('@')
	jg .no

	jmp .yes		; other possibilities exhausted
				; this must be punctuation of some kind

	.yes:
		add sp, 2
		clc		; clear carry (is punctuation)
		jmp .return
	.no:
		add sp, 2
		stc		; set carry (not punctuation)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


isupper:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	cmp ax, 'A'
	jl .no
	cmp ax, 'Z'		; 41h..5Ah (A..Z, ascii)
	jg .no

	.yes:
		clc		; clear carry (is uppercase)
		jmp .return
	.no:
		stc		; set carry (not uppercase)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret


isxdigit:
	push bp
	mov bp, sp
	push ax

	xor ax, ax		; initialize AX
	mov ax, [bp + 4]	; value to test

	push ax
	call isdigit
	jnc .yes

	.check_hexalpha_upper:
		cmp ax, 'A'
		jl .no
		cmp ax, 'F'	; 41h..46h (A..F, ascii)
		jg .check_hexalpha_lower

		jmp .yes

	.check_hexalpha_lower:
		cmp ax, 'a'
		jl .no
		cmp ax, 'f'	; 61h..66h (a..f, ascii)
		jg .no

	.yes:
		add sp, 2
		clc		; clear carry (is hex)
		jmp .return
	.no:
		add sp, 2
		stc		; set carry (not hex)
	.return:
		pop ax
		mov sp, bp
		pop bp
		ret
%endif
