%ifndef _STRING_ASM
%define _STRING_ASM

; stack direction
; ---------------
; + = external
; - = local
;
; ^ must be getting old D:
;

; calling conventions
;	push COUNT
;	push SOURCE
;	push DESTINATION
;	call FUNCTION
;	add sp, 6 (^ in the case of three WORDS)
;
; In C, for instance, this translate to:
; FUNCTION (DESTINATION, SOURCE, COUNT);

memset:
	; Set memory with byte value
	push bp			; setup stack frame
	mov bp, sp		; ...
	push si
	push di
	push cx

	mov di, [bp + 4]	; destination address
	mov ax, [bp + 6]	; requested byte value
	mov cx, [bp + 8]	; count

	cld			; will decrement address ES:DI
	rep stosb		; while cx > 0
				; store byte AL in ES:DI

	pop cx
	pop di
	pop si
	mov sp, bp
	pop bp
	ret


memcpy:
	push bp			; setup stack frame
	mov bp, sp		; ...

	mov di, [bp + 4]	; destination buffer
	mov si, [bp + 6]	; source buffer
	mov cx, [bp + 8]	; count of characters to move

	cld
	rep movsb

	mov sp, bp
	pop bp
	ret


strlen:
	; Determine length of null terminated string
	; NOTE: 64k limit imposed
	push bp			; setup stack frame
	mov bp, sp		; ...
	push cx
	push si

	xor cx, cx		; cx is counter
	xor ax, ax		; ax is return value
	mov si, [bp + 2]	; string address
.loop:
	lodsb			; load byte from ES:SI into AL
	cmp al, 0		; zero?
	je .return		; if so, we're done
	inc cx			; if not, keep going
	jc .crash		; if we roll over CX the carry flag will be set (that's bad)

	jmp .loop

.crash:
	stc			; force carry flag on failure

.return:
	clc
	mov ax, cx
	pop si
	pop cx
	mov sp, bp
	pop bp
	ret


strnchr:
	; Find first occurence of character in a string
	push bp			; setup stack frame
	mov bp, sp		; ...
	push cx
	push dx
	push si

	xor ax, ax		; ax is return value
	mov si, [bp + 4]	; string address
	mov dx, [bp + 6]	; needle character
	mov cx, [bp + 8]	; counter
.loop:
	lodsb			; load byte at si
	cmp al, dl		; same as needle?
	je .return		; if true: return

	dec cx			; decrement counter
	jne .loop		; counter zero?

.return:
	mov ax, cx		; return index of character
	pop si
	pop dx
	pop cx
	mov sp, bp
	pop bp
	ret


strncmp:
	; Determine difference between two strings
	push bp			; setup stack frame
	mov bp, sp		; ...
	push bx			; save registers
	push dx
	push si
	push di

	mov di, [bp + 4]	; string2 address
	mov si, [bp + 6]	; string1 address
	mov cx, [bp + 8]	; limit to compare

.loop:
	mov bx, [si]		; string1
	mov dx, [di]		; string2
	inc si			; next address, string1
	inc di			; next address, string2
	dec cx			; decrease byte counter

	cmp bx, dx		; compare bytes
	jne .diff		; Just die if not-equal

	cmp cx, 0		; If equal, check for null termination
	jne .loop

.diff:
	cmp bx, dx
	jg .s1_larger
	jl .s1_smaller
	je .return

.s1_smaller:
	mov ax, -1
	jmp .return

.s1_larger:
	mov ax, cx

.return:
	pop di			; cleanup stack
	pop si
	pop dx
	pop bx
	mov sp, bp
	pop bp
	ret


%endif	; _STRING_ASM
