bits 16

jmp kmain

%include "constants.asm"
%include "string.asm"
%include "disk.asm"
%include "console.asm"
%include "stdio.asm"


kmain:
	cli			; disable interrupts
	mov ax, cs		; get code segment (i.e. far jump address in bootloader)
	mov ds, ax		; set data segment
	mov es, ax		; set extra segment
	mov ax, 06000h
	mov ss, ax		; set stack segment
	mov sp, 0ffffh		; set stack pointer (~64k)
	sti			; enable interrupts

	mov [drive0], dx	; store bootloader's drive number

	; reset general purpose registers
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	xor si, si
	xor bp, bp


	push banner
	call puts

.mainloop:
	call kbd_read
	call putc

	jmp .mainloop

	cli
	jmp $


panic:
	; Hang system with supplied error message
	push bp
	mov bp, sp

	push error_msg_panic	; i.e. 'PANIC:'
	call puts
	add sp, 2

	push word [bp + 4]	; address of error string buffer
	call puts		; print error
	add sp, 2

	cli			; disable interrupts
	jmp $			; hang (no return)
				; stack is dead


; data
kernel_address: dd 0	; format DS:ADDR
banner: db "+========================+", CR, LF
	db "| Welcome to MINOS 0.0.1 |", CR, LF
	db "+========================+", CR, LF
	db CR, LF, 0

; Error messages
error_msg_panic: db "PANIC: ", 0


times 512 * 16 db 0
dw 0xefbe
