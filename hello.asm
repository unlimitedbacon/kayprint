bdos     .equ 0x0005
printstr .equ 9

    .org 0x100

start:
    ld c, printstr
    ld de, string
    call bdos
    ret

string:
    .db "Hello World!\n$", 0
