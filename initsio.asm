; This file is Intel 8080 assembly
SIOCR	EQU	06h		;Serial Port Control Register
SIODR	EQU	04h		;Serial Port Data Register

        org     100h

; Initialize the SIO from the values in initTbl

	lxi	h,initTbl	;hl->SIO initialization table
	mov	b,m		;b=bytes in table
iniLoop	inx	h
	mov	a,m		;next byte from table
	out	SIOCR
	dcr	b
	jnz	iniLoop		;loop until all bytes sent
	ret

; SIO initialization table

initTbl	db	9		; Size of table
	db	18H		; Channel RESET to SIO
	db	4,44h		; WR4: Clock divider, 1 stop bit,no parity
	db	1,0		; WR1: no interrupts
	db	3,0c1h		; WR3: 8 bits/ch, no auto enable, enable RCVR
	db	5,0EAh		; WR5: 8 bits/ch, set DTR & RTS
