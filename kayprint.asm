; Kayprint
; ========
; A CPM program for controlling 3D printers over serial

; CPM BDOS System Calls
; https://seasip.info/Cpm/bdosfunc.html
bdos        .equ 0x0005
C_READ      .equ 1
C_WRITE     .equ 2
A_READ      .equ 3	; Reader (RDR) input
A_WRITE     .equ 4	; Punch (PUN) output
C_RAWIO     .equ 6
C_WRITESTR  .equ 9
C_STAT      .equ 11
F_OPEN      .equ 15
F_READ      .equ 20
F_DMAOFF    .equ 26

; Serial IO Settings (modem port)
; These values are for a Kaypro II
SERDATA     .equ 4
SERSTATUS   .equ 6
TXRDY       .equ 4
RXRDY       .equ 1

; File Control Block (like a file handle in Unix)
; http://seasip.info/Cpm/fcb.html
; http://www.gaby.de/cpm/manuals/archive/cpm22htm/ch5.htm#Figure_5-2
fcb         .equ 0x005c         ; FCB automatically created by CPM from first CLI argument
fcb_cr      .equ fcb + 0x20 

buff        .equ 0x0080         ; Default location for 128 byte DMA buffer for file reads
ring        .equ 0x1000         ; Our ring buffer for storing responses from serial


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
    ;cp 1
    ;jr z, end
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
        ld c, C_WRITE
        call bdos
    pop hl \ pop de \ pop bc

    ; Filter out CR
    ; Smoothieware sends double OKs if you use CRLF line endings
    ld a, '\r'
    cp e
    jr z, _

    ; Print character from buffer to serial port
    ld a, e
    call ser_tx

    ; If we just sent a \n, wait for a reponse
_:  ld a, '\n'
    cp e
    jr nz, skip_read

    ; Receive data over serial until we see the string "ok"
    push bc \ push hl
        ; Print a tab to the console
        ld c, C_WRITE
        ld e, '\t'
        call bdos

        ld hl, ring
read_loop:
        ; Get a char over serial
        call ser_rx_wait

        ; Put character into ring buffer
        ld (hl), a
        ; Echo character to console
        push af \ push hl
            ld c, C_WRITE
            ld e, a
            call bdos
        pop hl \ pop af
        ; Check if the last bytes in buffer are "ok" with either LF or CRLF line ending
        ; For some reason smoothie sends both -_-
        push hl
            cp '\n'
            jr nz, ++_
            dec l
            ld a, (hl)
            cp '\r'
            jr nz, _
            dec l
            ld a, (hl)
_:          cp 'k'
            jr nz, _
            dec l
            ld a, (hl)
            cp 'o'
            jr nz, _
            ; Continue
        pop hl
        jr read_done
            
_:
        pop hl
        inc l       ; Will overflow at 256 bytes, so we have a 256 byte ring buffer
        jr read_loop
        
read_done:
    pop hl \ pop bc
skip_read:

    ; Adjust counters and loop
    inc hl
    dec b
    jp nz, print_loop
    jp buffer_loop

end:
    ret

; Subroutines
; ===========

;; ser_tx
;;  Send byte to serial port
;;  Blocks until serial port is ready
;; Inputs:
;;  A: Byte to send
ser_tx:
    push af
ser_tx_loop:
        call check_kbd
        in a, (SERSTATUS)
        and TXRDY
        jr z, ser_tx_loop
    pop af
	out (SERDATA), a
    ret


;; ser_rx
;;  Receive byte from serial port
;;  Non-blocking
;; Outputs:
;;  A: Byte read (if available)
;;  F: NZ if success, Z if no byte available
ser_rx:
    in a, (SERSTATUS)
    and RXRDY
    ret z
    in a, (SERDATA)
    ret

;; ser_rx_wait
;;  Receive byte from serial port
;;  Waits until a byte is available
;; Outputs:
;;  A: Byte read
ser_rx_wait:
    call check_kbd
    call ser_rx
    jr z, ser_rx_wait
    ret

;; check_kbd
;;  Checks if a key has been pressed and acts accordingly
check_kbd:
    ;; Get character from console
    push bc \ push de \ push hl
        ld c, C_RAWIO
        ld e, 0xFF  ; Read without echoing
        call bdos
    pop hl \ pop de \ pop bc
    ;; Return if 0 (no char waiting)
    or a
    ret z
    ;; Check escape key
    cp 0x1b
    call z, bail
    ret
 
;; bail
;;  Exit program and return to CPM
bail:
    ;; Load CPM return address from bottom of stack
    ld sp, stack-2
    ;; Return to CPM
    ret

;; read_error
;;  Prints error code encountered when reading file
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
_:  ld de, err_unknown
    call bdos
    ret

; String Constants
; ================
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

; Stack area
; ==========
.fill 32    ; 16 stack entries
stack:
    .dw 0

; Variables
; =========
last_line:  .dw ring

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

