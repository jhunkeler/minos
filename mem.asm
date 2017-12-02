%ifndef __MEM_ASM
%define __MEM_ASM

check_a20:
	pushf				; preserve flags
	push ds				; data segment
	push es				; extra segment
	push di				; destination index
	push si				; source index

	cli				; disable interrupts

	xor ax, ax			; zero out ax
	mov es, ax			; zero out extra segment

	not ax				; flip all bits in ax
	mov ds, ax

	mov di, 0x0500			; destination address
	mov si, 0x0510			; source address

	mov al, byte [es:di]		; copy byte from destination (FFFF:0500)
	push ax

	mov al, byte [ds:si]		; copy byte from source (FFFF:0510)
	push ax

	mov byte [es:di], 0x00		; set es:di to 0
	mov byte [ds:si], 0xFF		; set es:si to 255

	cmp byte [es:di], 0xFF		; did it wrap around?

	pop ax
	mov byte [ds:si], al

	pop ax
	mov byte [es:di], al

	mov ax, 0
	je check_a20__exit

	mov ax, 1

check_a20__exit:
	sti				; enable interrupts
	pop si				; restore registers
	pop di
	pop es
	pop ds
	popf				; restore flags

	ret


enable_a20:				; fast A20
	cli				; disble interrupts
	call check_a20			; is A20 already enabled?
	cmp al, 1
	je .no_a20

	in al, 0x92			; enable A20
	test al, 2
	jnz .return
	or al, 2
	and al, 0xFE
	out 0x92, al
	jmp .return
.no_a20:
	stc				; set carry on failure
.return:
	sti				; enable interrupts
	clc				; clear carry
	ret

%endif
