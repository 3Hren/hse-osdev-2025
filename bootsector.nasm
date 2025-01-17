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

    ; Clear interrupt flag in CPU "flags" register.
    cli
    ; Switch CPU to power-safe mode. It will stay there forever since we cleared up the interrupt flag.
    hlt

; TODO: Prints content in SI register until "\0".
print:
    pusha
    popa

BOOT_DRIVE:
    db 0x0
