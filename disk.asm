%ifndef _DISK_ASM
%define _DISK_ASM

%include "stdio.asm"

disk_info:
	push bp
	mov bp, sp

	xor dx, dx
	mov ah, 41h
	mov bx, 55aah
	mov dl, [bp + 4]	; drive number {80h..ffh}
	int 13h
	jc .return

	shr ax, 8
	push dx
	push cx
	push ax
	push disk_info_fmt
	call printf
	add sp, 6
.return:
	mov sp, bp
	pop bp
	ret

disk_last_status:
	push bp
	mov bp, sp

					; DL = drive number
	mov ah, 01h			; BIOS get status of last drive operation
	int 13h				; BIOS disk service
					; carry set on error
	mov sp, bp
	pop bp
	ret


disk_convert_status:
	push bp
	mov bp, sp
	pusha

	cmp ax, 01h			; Avoid writing "success" message
	jl .return

	xor cx, cx
	mov cx, ax			; AL contains the sector count
	and cx, 00ffh			; store in CX
	shr ax, 8			; shift error code into AL

					; This block handles AL when not 00h..11h
					; The extended error values have no real order
	cmp al, 20h
	je .status_20

	cmp al, 40h
	je .status_40

	cmp al, 80h
	je .status_80

	cmp al, 0AAh
	je .status_AA

	cmp al, 0BBh
	je .status_BB

	cmp al, 0CCh
	je .status_CC

	cmp al, 0E0h
	je .status_E0

	cmp al, 0FFh
	je .status_FF

	jmp .convert				; No match, convert AL as-is

						; Adjust error code so that it can be indexed
						; easily by error_msg_disk_table
	.status_20:
		mov al, 12h
		jmp .convert

	.status_40:
		mov al, 13h
		jmp .convert

	.status_80:
		mov al, 14h
		jmp .convert

	.status_AA:
		mov al, 15h
		jmp .convert

	.status_BB:
		mov al, 16h
		jmp .convert

	.status_CC:
		mov al, 17h
		jmp .convert

	.status_E0:
		mov al, 18h
		jmp .convert

	.status_FF:
		mov al, 19h
		jmp .convert

	.convert:
		mov bx, ax			; Get array index
		imul bx, bx, 2			; Calculate index offset
						; in human speak: idx * (idx * WORD)

		lea si, [error_msg_disk_table]	; Load address of table into source index
		add si, bx			; Add calculated index offset

	and dx, 00ffh				; get drive number

	push word [si]				; error message
	push dx					; drive number
	push ax					; error code
	push error_msg_disk_status_fmt
	call printf				; Print error message
	add sp, 8				; Clean up stack

.return:
	popa
	mov sp, bp
	pop bp
	ret


disk_lba_chs:
	push bp
	mov bp, sp

	mov ax, word [bp - 2]	; LBA

	mov sp, bp
	pop bp
	ret

disk_reset:
	push bp
	mov bp, sp
	pusha

	mov ah, 00h		; reset disk
	mov dl, [bp + 4]	; disk number
	int 13h			; BIOS disk service
	jnc .success

.success:
	popa
	mov sp, bp
	pop bp
	ret


disk_read:
	push bp
	mov bp, sp

	push di
	mov di, 3		; retry counter
.readloop:
	push ax
	push bx
	push cx
	push dx

				; AL = Sectors to read
				; ES:BX = Buffer address
				; CH = Cylinder (10 bits [6 & 7 of CL are MSB])
				; CL = Sector (5 lower bits)
				; DH = Head
				; DL = Drive
	mov ah, 02h		; BIOS - read disk sectors
	int 13h			; BIOS disk service

	jnc .success

	call disk_convert_status

	push dx
	call disk_reset
	add sp, 2


	pop dx
	pop cx
	pop bx
	pop ax


	dec di
	jnz .readloop

.success:
	pop di
	mov sp, bp
	pop bp
	ret


; data
align 2
drive0: dw 0

msg_disk_reset: db "Drive reset successful.", CR, 0
msg_disk_read: db "Sector read successful.", CR, 0

error_msg_disk_reset: db "Drive reset failed!", CR, 0
error_msg_disk_read: db "Drive read failed!", CR, 0

disk_info_fmt: db 'HDD(%c): INT 13h Ext: %x (%x)', CR, 0
error_msg_disk_status_fmt: db 'ERROR %x: Drive %x: %s', CR, 0
error_msg_disk:
	eds_success: db "Success", 0					; 00h
	eds_invalid_command: db "Invalid command", 0
	eds_address_mark: db "Cannot find address mark", 0
	eds_write_protected: db "Attempted write on write protected disk", 0
	eds_sector_not_found: db "Sector not found.", 0
	eds_reset_failed: db "Reset failed.", 0
	eds_disk_change_line_active: db "Disk change line active", 0
	eds_drive_parameter_activity_failed: db "Drive parameter activity failed", 0
	eds_dma_overrun: db "DMA overrun", 0
	eds_dma_boundary_64: db "DMA over 64kb boundary", 0
	eds_bad_sector: db "Bad sector detected", 0
	eds_bad_cylinder: db "Bad cylinder detected", 0
	eds_media_type_not_found: db "Media type not found", 0
	eds_invalid_number_of_sectors: db "Invalid number of sectors", 0
	eds_control_data_address_mark: db "Control data address mark detected", 0
	eds_dma_out_of_range: db "DMA out of range", 0
	eds_crc_ecc_data_error: db "CRC/ECC data error", 0	 	; 10h
	eds_ecc_corrected_data_error: db "ECC corrected data error", 0	; 11h
	; Everything was normal until... this...
	eds_controller_failure: db "Controller failure", 0		; 20h
	eds_seek_failure: db "Seek failure", 0				; 40h
	eds_timeout: db "Drive timed out (not ready?)", 0		; 80h
	eds_not_ready: db "Drive not ready", 0				; AAh
	eds_undefined_error: db "Undefined error", 0			; BBh
	eds_write_fault: db "Write fault", 0				; CCh
	eds_status_error: db "Status error", 0				; E0h
	eds_sense_operation_failed: db "Sense operation failed", 0	; FFh

error_msg_disk_table:				; is an array of pointers for each error message
	dw eds_success
	dw eds_invalid_command
	dw eds_address_mark
	dw eds_write_protected
	dw eds_sector_not_found
	dw eds_reset_failed
	dw eds_disk_change_line_active
	dw eds_drive_parameter_activity_failed
	dw eds_dma_overrun
	dw eds_dma_boundary_64
	dw eds_bad_sector
	dw eds_bad_cylinder
	dw eds_media_type_not_found
	dw eds_invalid_number_of_sectors
	dw eds_control_data_address_mark
	dw eds_dma_out_of_range
	dw eds_crc_ecc_data_error
	dw eds_ecc_corrected_data_error
	dw eds_controller_failure
	dw eds_seek_failure
	dw eds_timeout
	dw eds_not_ready
	dw eds_undefined_error
	dw eds_write_fault
	dw eds_status_error
	dw eds_sense_operation_failed
	dw 0000h				; END of error_msg_disk_table

%endif ; _DISK_ASM
