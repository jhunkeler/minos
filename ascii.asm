%ifndef _ASCII_ASM
%define _ASCII_ASM

NUL equ 00h	; null
SOH equ 01h	; start of heading
STX equ 02h	; start of text
ETX equ 03h	; end of text
EOT equ 04h	; end of transmission
ENQ equ 05h	; enquiry
ACK equ 06h	; acknowledge
BEL equ 07h	; bell (audible)
BS  equ 08h	; backspace
TAB equ 09h	; horizontal tab
LF equ 0Ah	; line feed
VT equ 0Bh	; vertical tab
FF equ 0Ch	; form feed
CR equ 0Dh	; carriage return
SHO equ 0Eh	; shift out
SHI equ 0Fh	; shift in
DLE equ 10h	; data link escape
DC1 equ 11h	; device control 1
DC2 equ 12h	; device control 2
DC3 equ 13h	; device control 3
DC4 equ 14h	; device control 4
NAK equ 15h	; negative acknowledge
SYN equ 16h	; synchronous idle
ETB equ 17h	; end of transmission block
CAN equ 18h	; cancel
EM equ 19h	; end of medium
SUBST equ 1Ah	; substitute
ESC equ 1Bh	; escape
FSEP equ 1Ch	; file separator
GSEP equ 1Dh	; group separator
RSEP equ 1Eh	; record separator
USEP equ 1Fh	; unit separator
SPC equ 20h	; space

%endif
