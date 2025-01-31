[bits 16]

GLOBAL switch_gdt

; EAX - pointer to GDT.
; EDX - drive number.
switch_gdt:
    mov eax, [esp + 4]
    mov edx, [esp + 8]

    cli
    lgdt [eax]

    mov eax, cr0
    or eax, 1
    mov cr0, eax ; Protected mode

    jmp 0x08:_start32
    
[bits 32]
_start32:
    mov eax, 0x10
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    mov eax, 0x10000
    push edx
    call eax