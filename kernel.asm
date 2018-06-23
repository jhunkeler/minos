bits 16

jmp kmain

%include "constants.asm"
%include "types.asm"
%include "string.asm"
%include "isr.asm"
%include "disk.asm"
%include "console.asm"
%include "stdio.asm"
%include "terminal.asm"		; eventually will become its own "program"


kmain:
	cli			; disable interrupts
	mov ax, cs		; get code segment
	mov ds, ax		; set data segment
	mov es, ax		; set extra segment
	mov ax, 9000h
	mov ss, ax		; set stack segment
	mov sp, 0FBFFh		; set stack pointer (~64k)
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

	mov dl, 0			; select video page 0
	call console_set_video_page	; set video page

	call cls			; clear console

	push 0000h			; home the cursor
	call setcursor
	add sp, 2

	push banner
	call printf
	add sp, 2

	push word [drive0]
	push sp
	push ss
	push sp
	push ss
	push kend
	push cs
	push kmain
	push cs
	push kend
	push cs
	push kmain
	push cs
	push msg_entry_point_fmt
	call printf
	add sp, 2 * 14

	mov dx, 0000h				; dx = diskette drive number
	.info_diskette_loop:			; display diskette drive data
		push dx				; load drive number (0-3)
		call disk_info			; show info
		add sp, 2

		inc dx				; next drive
		cmp dl, 03h			; for 3 devices
		jle .info_diskette_loop		; continue

	mov dx, 0080h				; dx = drive number (128+n)
	.info_disk_loop:			; display hard drive data
		push dx				; load drive number (80h-81h)
		call disk_info                  ; show info
		add sp, 2

		push dx				; next drive
		call disk_info_ext		; show drive extensions
		add sp, 2

		inc dx				; next drive
		cmp dx, 81h			; for 2 devices
		jle .info_disk_loop		; continue

.preload:
	call isr_inject

.mainloop:
	call terminal
	jmp .mainloop

	cli
	jmp $


isr_inject:
	push bp
	mov bp, sp

	push es
	push ax
	push bx
	push bp

	mov ax, 0000h		; set ES to Interrupt Vector Table
				; (start of RAM)
	mov es, ax

	mov bp, 20h * 4		; Set vector (v = es:offset * 4))
	lea bx, [int22]		; Load address of ISR routine
	mov ax, cs		; Load code segment into AX

	mov word [es:bp], bx	; Store address of ISR routine
	mov word [es:bp+2], ax	; Store code segment of ISR routine

	push bx
	push ax
	push msg_isr_fmt
	call printf		; print injected ISR address
	add sp, 2 * 3		; cleanup stack

	pop bp
	pop bx
	pop ax
	pop es

	int 20h			; test new ISR

	mov sp, bp
	pop bp
	ret


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
banner: db "+========================+\n"
	db "| Welcome to MINOS 0.0.1 |\n"
	db "+========================+\n"
	db "\n", 0

msg_entry_point_fmt:
	db 'Kernel address:	%5x:%4x - %5x:%4x (%d:%d - %d:%d)\n'
        db 'Stack address :	%5x:%4x (%d:%d)\n'
        db 'Boot device   :    %2x\n\n', 0
msg_isr_fmt: db "ISR %5x:%4x\n", 0

; Error messages
error_msg_panic: db "PANIC: ", 0

kend: dw 0xefbe			; The "BEEF" signature is a visual "end of kernel"
times (1474560-512)-($-$$) db 0	; Until we have a file system reserve 1.44MBs
