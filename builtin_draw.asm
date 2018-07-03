%ifndef _BUILTIN_DRAW_ASM
%define _BUILTIN_DRAW_ASM

%include "constants.asm"

jmp builtin_draw

align 1
builtin_draw_storage_active: db 00h
builtin_draw_exit: db 00h

align 2
builtin_draw_kbd_data: dw 0000h
builtin_draw_cursor_pos: dw 0000h


builtin_draw:
	push bp
	mov bp, sp
	pusha

	mov bx, 0
	mov dx, 07h

	.get_input:
		call builtin_draw_input
		call builtin_draw_perform
		;call builtin_draw_cursor_bounds_check
		cmp byte [builtin_draw_exit], 0
		jnz .return
		jmp .get_input
	.return:
		mov byte [builtin_draw_exit], 0		  ; reset exit status
		;mov byte [builtin_draw_storage_active], 0 ; reset storage state
		popa
		mov sp, bp
		pop bp
		ret


builtin_draw_input:
	mov ah, 01h
	int 16h
	jz .end

	mov [builtin_draw_kbd_data], ax

	mov ah, 00h
	int 16h

	.end:
		ret

builtin_draw_cursor_setup:
	mov ah, 02
	mov bh, 0
	mov dx, [builtin_draw_cursor_pos]
	ret


builtin_draw_toolbar:
	push es
	push ax
	mov ax, 0b800h			; set ES to video ram
	mov es, ax
	mov [es:0xf9e], byte 'C'	; direct write
	mov [es:0xf9f], dl		; direct write current COLOR
	pop ax
	pop es
	ret
	.msg_color: db 'Color:',0


builtin_draw_perform:
	push bp
	mov bp, sp

	call builtin_draw_toolbar
	jz .end

	mov ax, [builtin_draw_kbd_data]

	cmp al, 1bh		; ESC
	je .kill_program

	cmp ah, 3fh		; F5
	je .store_page

	cmp ah, 43h		; F9
	je .restore_page

	cmp ah, 4bh		; Left arrow
	je .cursor_left

	cmp ah, 4dh		; Right arrow
	je .cursor_right

	cmp ah, 50h		; Down arrow
	je .cursor_down

	cmp ah, 48h		; Up arrow
	je .cursor_up

	cmp al, '-'		; Minus
	je .color_down

	cmp al, '+'		; Plus
	je .color_up

	cmp al, 'f'		; f
	je .color_fill

	jmp .output

	.kill_program:
		mov byte [builtin_draw_exit], 1
		jmp .end

	.store_page:
		push ds
		push es

		mov ax, VIDEO_RAM 			; source
		mov ds, ax
		mov si, 0000h				; color text memory

		;mov ax, word [builtin_draw_storage_segment]	; destination segment
		mov ax, .STORAGE_SEGMENT
		mov es, ax
		mov di, 0000h				; page storage

		mov cx, 80 * 25

		cld
		rep movsw
		;mov byte [builtin_draw_storage_active], 1	; We have stored a page

		pop es
		pop ds
		jmp .end

	.restore_page:
		;cmp byte [builtin_draw_storage_active], 1	; Is there a page to restore?
		;jne .end

		push ds
		push es

		;mov ax, word [builtin_draw_storage_segment]	; source segment
		mov ax, .STORAGE_SEGMENT
		mov ds, ax
		mov si, 0000h				; page storage

		mov ax, VIDEO_RAM			; destination segment
		mov es, ax
		mov di, 0000h				; color text memory

		mov cx, 80 * 25

		cld
		rep movsw

		pop es
		pop ds
		jmp .end

	.cursor_up:
		push ax
		push bx
		push dx

		call builtin_draw_cursor_setup
		cmp dh, 0
		je .cursor_done

		dec dh
		int 10h
		mov [builtin_draw_cursor_pos], dx

		jmp .cursor_done

	.cursor_down:
		push ax
		push bx
		push dx

		call builtin_draw_cursor_setup

		cmp dh, 22
		jg .cursor_done

		inc dh
		int 10h
		mov [builtin_draw_cursor_pos], dx
		jmp .cursor_done

	.cursor_left:
		push ax
		push bx
		push dx

		call builtin_draw_cursor_setup
		cmp dl, 0
		je .cursor_done

		dec dl
		int 10h
		mov [builtin_draw_cursor_pos], dx
		jmp .cursor_done

	.cursor_right:
		push ax
		push bx
		push dx

		call builtin_draw_cursor_setup
		cmp dl, 78
		jg .cursor_done

		inc dl
		int 10h
		mov [builtin_draw_cursor_pos], dx
		jmp .cursor_done

	.cursor_done:
		pop dx
		pop bx
		pop ax
		jmp .end

	.color_down:
		sub dl, 0x10
		jmp .end

	.color_up:
		add dl, 0x10
		jmp .end

	.color_fill:
		push ax
		push bx
		push cx
		push dx

		mov ah, 06h
		mov al, 24
		mov bh, dl
		mov ch, 0
		mov cl, 0
		mov dh, 23
		mov dl, 79
		int 10h

		pop dx
		pop cx
		pop bx
		pop ax
		jmp .output

	.output:
		mov ah, 09h
		mov al, 20h
		mov bh, 0
		mov bl, dl
		mov cx, 1
		int 10h

		mov word [builtin_draw_kbd_data], 0000h

	.end:
		mov sp, bp
		pop bp
		ret

	.STORAGE_SEGMENT equ 7000h

%endif
