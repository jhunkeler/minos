%ifndef _CONSTANTS_ASM
%define _CONSTANTS_ASM

MAX_ROWS equ 25
MAX_COLS equ 80
LENGTH_ROW equ 0A0h	; NOTE: length in bytes (80 * 2 = 160)
LENGTH_COL equ 02h	; NOTE: length in bytes (1 * 2 = 2)

%include "colors.asm"
%include "ascii.asm"		; ASCII control codes
%include "scancodes.asm"	; Keyboard scancodes

%endif

