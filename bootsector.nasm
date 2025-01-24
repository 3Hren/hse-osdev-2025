[bits 16]

GLOBAL _start

; Entry point.
_start:
    ; BIOS stores our boot driver in "dl" register, so it's better to save it.
    mov [BOOT_DRIVE], dl

    ; Set up our stack. Remember, that it grows down.
    ;
    ; Here 0x7c00 is just some address, that we use as a stack.
    mov bp, 0x7c00
    mov sp, bp

    mov  si, MSG_BOOTING
    call print
    mov  si, [BOOT_DRIVE]
    and  si, 0x00ff
    call print_hex
    mov  si, MSG_NEWLINE
    call print
    mov  si, HACK
    call print

    ; Clear interrupt flag in CPU "flags" register.
    cli
    ; Switch CPU to power-safe mode. It will stay there forever since we cleared up the interrupt flag.
    hlt

; Prints content in SI register until "\0".
; TODO: Consider out why the last byte is not printed.
print:
    pusha
    mov ah, 0x0e
    cld          ; Clear direction flag, so "lodsb" will move forward.
_print_loop:
    ; Loads a byte form "SI" register to "AL".
    ; Then "SI" register is incremented in case of "DF" flag cleared.
    lodsb
    test al, al
    jz   _print_loop_end
    int  0x10
    jmp  _print_loop
_print_loop_end:
    popa
    ret

; Prints 16-bit number in hex format.
print_hex:
    pusha
    xor cx, cx
_print_hex_loop:
    cmp cx, 4
    je  _print_hex_loop_end
    mov ax, si
    and ax, 0x000f
    add al, 0x30              ; + '0'.
    cmp al, 0x39              ; Compare with '9'.
    jle _print_hex_loop_step2
    add al, 0x27              ; If greater - add 'a' - '9' - 1
_print_hex_loop_step2:
    mov bx,   HEX_BUF + 5
    sub bx,   cx
    mov [bx], al
    ror si,   4
    inc cx
    jmp _print_hex_loop
_print_hex_loop_end:
    mov  si, HEX_BUF
    call print
    popa
    ret

BOOT_DRIVE:
    db 0x0

MSG_BOOTING:
    db "[] Boot from ", 0

MSG_NEWLINE:
    db 0xd, 0xa, 0

HEX_BUF:
    db "0x0000", 0

HACK:
    db 1, 0
