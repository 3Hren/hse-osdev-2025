[bits 16]

GLOBAL start32

; EAX - pointer to GDT.
; EDX - drive number.
start32:
    mov  eax, [esp + 4]
    mov  edx, [esp + 8]
    ; We have to disable CPU interrupts, because BIOS interrupt vector will
    ; interfere with us.
    ;
    ; We'll enable them later when we set our own interrupt vector.
    cli                 
    lgdt [eax]          ; Load our GDT.
    mov  eax, cr0
    or   eax, 1
    mov  cr0, eax       ; Set protected mode flag.
    jmp  0x08:_start32  ; Far jump to our 32-bit code. This flushes CPU pipeline.

[bits 32]
_start32:
    mov ax,  0x10    ; Setup the segment registers with data selector.
    mov ds,  ax
    mov es,  ax
    mov fs,  ax
    mov gs,  ax
    mov ss,  ax
    mov ebp, 0x10000
    mov esp, ebp     ; Set protected mode stack pointer.

    mov  eax, 0x10000
    push edx
    call eax
