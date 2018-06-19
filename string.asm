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
	push bp                 ; setup stack frame
	mov bp, sp              ; ...
	push cx
	push si

	xor cx, cx              ; cx is counter
	xor ax, ax              ; ax is return value
	mov si, [bp + 4]        ; string address
.loop:
	lodsb                   ; load byte from ES:SI into AL
	cmp al, 0               ; zero?
	je .return              ; if so, we're done
	inc cx                  ; if not, keep going
	jmp .loop

.return:
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

strtok:
	push bp
	mov bp, sp

	push bx				; save GPRs
	push cx
	push dx
	push di
	push si

	xor ax, ax			; use: for delimter (LSB)
	xor bx, bx			; use: base address for effective address calculations
	xor cx, cx			; use: input string length counter
	xor dx, dx			; use: temp for string comparison
	xor si, si			; use: token array
	xor di, di			; use: input string

	mov di, [bp + 4]		; arg1 - input string (null terminated)
	mov si, [bp + 6]		; arg2 - address of token array
	mov al, [bp + 8]		; arg3 - delimter value

	cld				; clear direction flag

	.find_first:
		mov dl, byte [di]	; Load byte from input string
		cmp dl, al		; is it the delimiter?
		jne .calculate_length	; if not, calculate length of string at this address
		inc di			; else, scan next byte
		jmp .find_first

	.calculate_length:
		push ax			; save delimiter
		push di			; get length of null terminated string
		call strlen
		add sp, 2
		mov cx, ax		; count is return value
		pop ax			; restore delimiter

		lea bx, [di]		; load initial address for _no_adjust
		jmp .strtok_record_no_adjust


	.strtok_record_eos:
		mov byte [di], 0	; Null terminate token

	.strtok_record:
		lea bx, [di + 1]	; The address following the null terminated token
					; points to our new token address

	.strtok_record_no_adjust:
		mov [si], bx		; store address in results array
		add si, 2		; increment results array by one WORD
		inc di			; increment input string
		dec cx			; decrement input string length counter

	.strtok_scan:
		mov dl, byte [di]	; load byte from input string
		cmp dl, 0		; is it the end of the string?
		je .strtok_return

		cmp dl, al		; is this the delimiter?
		je .strtok_record_eos	; if yes, record the address

		dec cx			; decrement input string length counter
		inc di			; increment input string
		jmp .strtok_scan	; loop until scanning is done

	cmp cx, 0			; if the counter is not zero there's more to parse
	jne .strtok_record		; loop until token parsing is done


.strtok_return:
	mov ax, [bp + 6]		; return token array

	pop si				; restore GPRs
	pop di
	pop dx
	pop cx
	pop bx

	mov sp, bp
	pop bp
	ret

%endif	; _STRING_ASM
