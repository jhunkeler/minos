%ifndef _CONSOLE_ASM
%define _CONSOLE_ASM

%include "constants.asm"
%include "stdio.asm"
%include "string.asm"
%include "keyboard.asm"

MAX_ROWS equ 25
MAX_COLS equ 80

putc:
	; Write single character at cursor position
	push bp
	mov bp, sp
	pusha

	cmp al, 20h
	jl .non_graphical

	mov ah, 0ah		; BIOS - write character
	mov bx, 00h		; video page zero
	mov cx, 01h		; repeat character N times
	int 10h			; BIOS video service

.non_graphical:
	push ax
	call console_driver
	add sp, 2

	popa
	mov sp, bp
	pop bp
	ret


console_scroll_up:
	cmp dh, MAX_ROWS - 1
	jne .no_action

	mov dh, MAX_ROWS - 2
	push dx
	call setcursor
	add sp, 2

	; scroll window up:
	mov     ah, 06h ; scroll up function id.
	mov     al, 1   ; lines to scroll.
	mov     bx, 0700h  ; attribute for new lines.
	mov     cl, 0   ; upper col.
	mov     ch, 0   ; upper row.
	mov     dl, MAX_COLS   ; lower col.
	mov     dh, MAX_ROWS   ; lower row.
	int     10h
.no_action:
	ret


console_driver:
	push bp
	mov bp, sp

	call console_cursor_getpos
	mov dh, [cursor_row]
	mov dl, [cursor_col]

	mov ax, [bp + 4]

.do_fn:
.do_scancode:
	cmp al, 00h			; when AL is 00h, check scan-code
	jne .do_ascii

	cmp ah, SC_ARROW_LEFT
	je .handle_sc_arrow_left

	cmp ah, SC_ARROW_RIGHT
	je .handle_sc_arrow_right


.handle_sc_arrow_left:
	dec dl
	jmp .return

.handle_sc_arrow_right:
	inc dl
	jmp .return

.do_ascii:
	; ASCII control block
	cmp al, SPC
	jae .handle_SPC

	cmp al, TAB
	je .handle_TAB

	cmp al, BS
	je .handle_BS

	cmp al, CR
	je .handle_CR

	cmp al, LF
	je .handle_LF

	; etc...
	jmp .return


.handle_SPC:
	inc dl
	cmp dl, MAX_COLS
	jge .handle_CR
	jmp .return

.handle_TAB:
	add dl, 4
	jmp .return

.handle_BS:
	dec dl
	cmp dl, 0
	jl .skip_bs

	push dx
	call setcursor
	add sp, 2

.skip_bs:
	mov ah, 0ah
	mov al, 20h
	mov bx, 00h
	mov cx, 1
	int 10h
	jmp .return_noupdate

.handle_CR:
	mov dl, 0		; set column zero

.handle_LF:
	inc dh			; increment row
	jmp .return

.return:
	push dx
	call setcursor
	add sp, 2


.return_noupdate:
	call console_scroll_up
	mov sp, bp
	pop bp
	ret


cls:
	push bp
	mov bp, sp
	pusha

	mov ah, 07h		; BIOS - scroll down
	mov al, 00h		; lines to scroll (0 == entire screen)
	mov bx, 0700h		; color white/black
				; & video page zero
	mov cx, 0
	mov dh, 24		; rows
	mov dl, 79		; cols
	int 10h			; BIOS video service
	popa

	mov sp, bp
	pop bp
	ret

console_cursor_getpos:
	push bp
	mov bp, sp
	pusha

	mov ah, 03h		; BIOS - query cursor position and size
	mov bh, 00h		; video page zero
	int 10h

	mov [cursor_sl_start], byte ch	; record data
	mov [cursor_sl_end], byte cl
	mov [cursor_row], byte dh
	mov [cursor_col], byte dl

	popa
	mov sp, bp
	pop bp
	ret

console_cursor_read:
	push bp
	mov bp, sp
	push ax
	push bx

	mov ah, 08h		; BIOS - read character/attr at cursor
	mov bh, 00h		; video page zero
	int 10h

	mov [cursor_attr], byte ah
	mov [cursor_char], byte al

	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret

console_cursor_read_last:
	push bp
	mov bp, sp
	push dx

	call console_cursor_getpos
	mov dh, [cursor_row]
	mov dl, [cursor_col]

	cmp dh, 0		; is this column zero?
	je .finalize

	sub dl, 1		; previous column
	js .prev_row		; column went negative
	jmp .finalize

.prev_row:
	cmp dh, 0		; is this row zero?
	je .return

	sub dh, 1		; go up one row
	add dl, 80		; return to last column of row (-1 + 80 = 79)

.finalize:
	push dx
	call setcursor
	call console_cursor_getpos
	call console_cursor_read

	; restore original cursor position
	mov dh, [cursor_row]
	mov dl, [cursor_col]
	push dx
	call setcursor
.return:
	add sp, 4
	pop dx
	mov sp, bp
	pop bp
	ret


setcursor:
	push bp
	mov bp, sp
	pusha

	mov ah, 02h		; BIOS - set cursor position
	mov bh, 0		; video page zero
	mov dx, [bp + 4]	; address of new cursor value
	int 10h			; BIOS video service

	popa
	mov sp, bp
	pop bp
	ret


; data
cursor_sl_start: db 0
cursor_sl_end: db 0
cursor_row: db 0
cursor_col: db 0
cursor_row_vram: dw 0
cursor_col_vram: dw 0
cursor_vram: dw 0
cursor_attr: db 0
cursor_char: db 0
%endif
