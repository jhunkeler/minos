%ifndef _VGA_DEMO_ASM
%define _VGA_DEMO_ASM

VGA_SCREEN_WIDTH equ 320
VGA_SCREEN_HEIGHT equ 200
VGA_COLORS equ 0x100

vga_plot:
	%define .x [bp + 4]
	%define .y [bp + 6]
	%define .color [bp + 8]
	push bp
	mov bp, sp
	pusha
	push es
	push ds
	;push ax
	;push cx
	;push dx
	;push di
;
	xor ax, ax
	xor cx, cx
	xor dx, dx
	xor di, di

	mov ax, 0A000h
	mov es, ax			; Store VGA memory segment in ES
	mov ds, ax

	mov ax, word VGA_SCREEN_WIDTH
	mov cx, word .y
	mul cx
	add ax, word .x
	mov di, ax

	mov ax, word .color
	mov [es:di], ax

	.return:
		;pop di
		;pop dx
		;pop cx
		;pop ax
		pop ds
		pop es
		popa
		mov sp, bp
		pop bp
		ret



builtin_vga_demo:
	push bp
	mov bp, sp
	sub sp, 2

	;
	; no arguments for this program
	;

	.main:
		mov ah, 0fh		; get current video mode
		int 10h
		mov [bp - 2], al	; save current video mode

		mov ah, 00h
		mov al, 13h		; set 256 color VGA mode
		int 10h

		mov di, 0ffh
		.loop:
			mov si, .data_smiley	; address of smiley face array
			mov cx, 10	; number of array elements
		.do_plot:
			mov ax, [si]	; Load coordinates
			add si, 2	; Next set

			movzx dx, al	; Store y
			movzx bx, ah	; Store x

			push di		; color
			push dx		; y
			push bx		; x
			call vga_plot	; write pixel
			add sp, 2 * 3

			and di, 0ffh	; DI overflows into infinity so
					; use its low byte instead of resetting to zero
			dec di		; Next color
			dec cx		; Next loop
			jne .do_plot

		xor ax, ax
		call kbd_read_async	; ZF=1 if no key is pressed
		je .loop

	.return:
		mov ah, 00h		; Set video mode
		mov al, [bp - 2]	; Restore video mode
		int 10h

		add sp, 2
		mov sp, bp
		pop bp
		ret

	.data_smiley:
		;  plots a smiley face using coordinates
		;  row col
		db 01h,01h	; left eye
		db 01h,05h	; right eye
		db 04h,03h	; nose
		db 06h,00h	; left uptick mouth
		db 06h,06h	; mouth
		db 07h,01h	; mouth
		db 07h,02h	; mouth
		db 07h,03h	; mouth
		db 07h,04h	; mouth
		db 07h,05h	; right uptick mouth

%endif
