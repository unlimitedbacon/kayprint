; cat
; Dumps a file to screen as well as serial output

; CPM BDOS System Calls
; https://seasip.info/Cpm/bdosfunc.html
bdos        .equ 0x0005
C_READ      .equ 1
C_WRITE     .equ 2
A_READ      .equ 3
A_WRITE     .equ 4
C_WRITESTR  .equ 9
F_OPEN      .equ 15
F_READ      .equ 20
F_DMAOFF    .equ 26

; Serial IO Settings
SERDATA     .equ 4
SERSTATUS   .equ 6
TXRDY       .equ 4
RXRDY       .equ 1

; File Control Block (like a file handle in Unix)
; http://seasip.info/Cpm/fcb.html
; http://www.gaby.de/cpm/manuals/archive/cpm22htm/ch5.htm#Figure_5-2
fcb         .equ 0x005c         ; FCB automatically created from first CLI argument
fcb_cr      .equ fcb + 0x20 

buff        .equ 0x0080         ; Default location for 128 byte DMA buffer

    .org 0x100

start:
    nop
    nop
    ; Get return pointer and set up stack
    pop bc
    ld sp, stack
    push bc
    ; Open file
    ld c, F_OPEN
    ld de, fcb
    call bdos
    ; Error if file not found
    cp 4
    jr c, _
    ld c, C_WRITESTR
    ld de, err_open
    call bdos
    jp end
_:

    ; Set CR to 0 to read from start of file
    xor a
    ld (fcb_cr), a
    
    ; Set location of buffer for reading data from file
    ld c, F_DMAOFF
    ld de, buff
    call bdos

buffer_loop:
    ; Read chunk of file into buffer
    ld c, F_READ
    ld de, fcb
    call bdos

    ; Check if that was the last chunk of file
    or a
    jr z, _
    cp 1
    jr z, end
    ; Report errors
    call read_error
    jr end
_:

    ; Loop through the buffer
    ld b, 128
    ld hl, buff
print_loop:

    ; Get char and check for end of file
    ; 0x1a signals end of ASCII file in CPM
    ld a, 0x1a
    ld e, (hl)
    cp e
    jr z, end
    

    ; Print character from buffer to console
    push bc \ push de \ push hl
        ; Print to console
        ld c, C_WRITE
        call bdos
    pop hl \ pop de \ pop bc
    push bc \ push de \ push hl
	ld a, e

        ; Print to serial
sertx:
        push af
sertxwait:
		in a, (SERSTATUS)
		and TXRDY
		jr z, sertxwait
        pop af
	out (SERDATA), a
        ; ret

    pop hl \ pop de \ pop bc

    ; Adjust counters and loop
    inc hl
    dec b
    jr nz, print_loop
    jr buffer_loop

end:
    ret

;; read_error
;; Inputs:
;;  A: Error code
;; Overwrites C, DE
read_error:
    ld c, C_WRITESTR
    cp 1
    jr nz, _
    ld de, err_eof
    call bdos
    ret
_:  cp 9
    jr nz, _
    ld de, err_fcb
    call bdos
    ret
_:  cp 10
    jr nz, _
    ld de, err_media_chng
    call bdos
    ret
_:  cp 11
    jr nz, _
    ld de, err_unlock
    call bdos
    ret
_:  cp 0xff
    jr nz, _
    ld de, err_hardware
    call bdos
    ret
_:  ld de, err_media_chng
    call bdos
    ret

err_open:
    .db "\nErr: Couldn't open file\n$"
err_eof:
    .db "\nErr 01: End Of File\n$"
err_fcb:
    .db "\nErr 09: Invalid FCB\n$"
err_media_chng:
    .db "\nErr 10: Media changed\n$"
err_unlock:
    .db "\nErr 11: Unlocked file verification\n$"
err_hardware:
    .db "\nErr_255: Hardware error\n$"
err_unknown:
    .db "\nUnknown Error\n$"

string:
    .db "Hello World!\n$", 0

.fill 15
stack:
    .dw 0

;fcb:
;    .db 0               ; Drive - 0 = Default
;    .db "TEST    "      ; Filename
;    .db "TXT"           ; Filetype
;    .db 0               ; EX
;    .db 0,0             ; S1, S2
;    .db 0               ; RC
;    .fill 16            ; AL
;    .db 0               ; CR
;    .db 0,0,0           ; R1, R2, R3
