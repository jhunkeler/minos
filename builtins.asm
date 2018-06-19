%ifndef _BUILTINS_ASM
%define _BUILTINS_ASM

%include "builtin_reboot.asm"
%include "builtin_exit.asm"
%include "builtin_echo.asm"

t_builtins_fn:
	dw builtin_echo
	dw builtin_exit
	dw builtin_reboot
	dw 0

t_builtins_str:
	.echo: db 'echo', 0
	.exit: db 'exit', 0
	.reboot: db 'reboot', 0
	dw 0
%endif
