[bits 16]
; Export "_start" symbol to suppress linker warnings.
GLOBAL _start
; Comment when the bootsector becomes stable.
%define DEBUG

; Entry point.
_start:
    ; BIOS stores our boot driver in "dl" register, so it's better to save it.
    mov [BOOT_DRIVE], dl

    ; Set up our stack. Remember, that it grows down.
    ;
    ; Here 0x7c00 is just some address, that we use as a stack.
    mov bp, 0x7c00
    mov sp, bp

    ; Zero segment registers.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; Enable A20.
    mov al,   2
    out 0x92, al

    ; Print banner to ensure we're ok.
    mov  si, MSG_BOOTING
    call print
    mov  si, [BOOT_DRIVE]
    and  si, 0x00ff
    call print_hex
    mov  si, MSG_NEWLINE
    call print

    ; Since the BIOS only loads the first 512 bytes of our disk, we are
    ; painfully limited in the number of instructions we can use.
    ; More precisely, we have only 446 bytes, and this is often not enough to
    ; completely initialize the system.
    ;
    ; Therefore, we need to load additional disk sectors into memory.
    mov  si,  _partition_table + 0x10
    mov  edi, _boot16                 ; "EDI" contains the target address.
    call read_boot16_partition

    mov  si,  _partition_table + 0x20
    mov  edi, _boot32                 ; "EDI" contains the target address.
    call read_boot16_partition

%ifdef DEBUG
    ; Print 2 bytes of the first 4 sectors to ensure we load correctly.
    mov  esi, _boot16
    call print_sectors

    mov  esi, _boot32
    call print_sectors
%endif

    ; Prepare arguments on stack and jump to the next program.
    push WORD [BOOT_DRIVE]
    jmp  boot16

; Prints "SI" content until "\0".
print:
    pusha
    ; Zero direction flag. It is honored in "LODSB" instruction (below).
    cld
    ; BIOS API: "int 0x10" with "AH = 0x0e" triggers scrolling teletype.
    mov ah, 0x0e
_print_loop:
    ; Loads a byte from "DS:SI" to "AL".
    ; The "SI" register is incremented or decremented automatically according
    ; to the setting of the "DF" flag in the "EFLAGS" register.
    ; If the "DF" flag is 0, the "SI" register is incremented.
    ; If the "DF" flag is 1, the "SI" register is decremented.
    lodsb
    test al, al
    je   _print_loop_end
    int  0x10
    jmp  _print_loop
_print_loop_end:
    popa
    ret

; Prints content of "SI" as hex.
print_hex:
    pusha
    ; Index.
    mov cx, 0
_print_hex_loop:
    cmp cx, 4                 ; Loop 4 times.
    je  _print_hex_loop_end
    ; Convert the last char of "DX" to ASCII.
    mov ax, si                ; Use "AX" as our working register.
    and ax, 0x000f            ; 0x1234 -> 0x0004 by masking first three to zeros.
    add al, 0x30              ; Add 0x30 ("0").
    cmp al, 0x39              ; If > "9", add offset to represent "a..f".
    jle _print_hex_loop_step2
    add al, 0x27
_print_hex_loop_step2:
    ; Get the correct position of the string to place our ASCII char.
    ; "BX" ::= BaseAddress + Length - Index.
    mov bx,   HEX_BUF + 5 ; BaseAddress + Length.
    sub bx,   cx          ; Index.
    mov [bx], al          ; Copy the ASCII char on "AL" to the position pointed by "BX".
    ror si,   4           ; 0x1234 -> 0x4123 -> 0x3412 -> 0x2341 -> 0x1234
    ; Continue loop.
    inc cx
    jmp _print_hex_loop
_print_hex_loop_end:
    mov  si, HEX_BUF
    call print
    popa
    ret

; Reads the next boot partition from disk into memory.
;
; SI  - partition table entry address.
; EDI - the target address.
;
; https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
; https://wiki.osdev.org/Partition_Table
read_boot16_partition:
    push bp
    mov  bp, sp

    ; Init DAP.
    mov ax,               [si + 0x08] ; LBA number.
    mov cx,               [si + 0x0c] ; Number of sectors.
    mov [_DAP_START_LBA], ax          ; Copy LBA number to the DAP structure.
    mov si,               DAP         ; "SI" must contain address of DAP in memory, const.
_read_boot16_partition_load:
    ; Break if no sectors left to read.
    test cx, cx
    jz   _read_boot16_partition_end

    ; Number of sectors to read at a time, truncated to 32 if "CX" is greater.
    mov ax, cx
    cmp ax, 32
    jle _read_boot16_partition_load_sectors_trim
    mov ax, 32
_read_boot16_partition_load_sectors_trim:
    mov WORD [_DAP_NUM_SECTORS],    ax
    ; Offset to memory buffer.
    mov dx,                         di
    and dx,                         0xf
    mov WORD [_DAP_OFF_MEMORY_BUF], dx
    ; Segment of memory buffer.
    mov edx,                        edi
    shr edx,                        4
    mov WORD [_DAP_SEG_MEMORY_BUF], dx

    xor dx, dx
    mov dl, [BOOT_DRIVE]
    mov ax, 0x4200
    int 0x13
    jc  _read_boot16_partition_panic

    ; Decrement the number of sectors left to read.
    xor eax,              eax
    mov ax,               WORD [_DAP_NUM_SECTORS]
    sub ecx,              eax
    ; Increment start LBA by "sectors read".
    ;
    ; Note that LBA is a 64-bit field, but we ignore its upper part, since
    ; 512 * (2^32 - 1) is approximately 2.9TB, which I hope is enough to boot
    ; our OS :).
    ; Also note that the lower half comes before the upper half.
    mov ebx,              [_DAP_START_LBA]
    add ebx,              eax
    mov [_DAP_START_LBA], ebx
    ; Increment "target address" (which is in "EDI") by "sectors read" * 512.
    shl eax,              9
    add edi,              eax

%ifdef DEBUG
    ; Print how many sectors were read and where. Just for debugging.
    mov ax, si

    mov  si, DBG_MSG_DISK_READ_OK
    call print

    mov  si, [_DAP_NUM_SECTORS]
    call print_hex

    mov  si, DBG_MSG_TO
    call print

    mov  edx, edi
    shr  edx, 16
    call print_hex

    mov  si, DBG_MSG_COLON
    call print

    mov  si, di
    call print_hex

    mov  si, MSG_NEWLINE
    call print

    mov si, ax
%endif

    jmp _read_boot16_partition_load
_read_boot16_partition_end:
    mov sp, bp
    pop bp
    ret
_read_boot16_partition_panic:
    mov  si, MSG_DISK_READ_FAIL
    call print
    jmp  $

%ifdef DEBUG
print_sectors:
    mov edi, esi
    mov cx,  4
_print_sectors_loop:
    test cx, cx
    jz   _print_sectors_loop_end

    mov  esi, [edi]
    call print_hex
    add  edi, 0x200       ; Move to the next sector.
    mov  si,  MSG_NEWLINE
    call print

    dec cx
    jmp _print_sectors_loop
_print_sectors_loop_end:
    ret
%endif

[bits 32]
boot16:
    call _boot16
    ; Clear interrupt flag in CPU "flags" register.
    cli
    ; Switch CPU to power-safe mode.
    ; It will stay there forever since we cleared up the interrupt flag.
    hlt

MSG_NEWLINE:
    db 0xd, 0xa, 0
MSG_BOOTING:
    db "[] MBR: drive ", 0
MSG_DISK_READ_FAIL:
    db "[] MBR: drive read fail", 0xd, 0xa, 0
%ifdef DEBUG
DBG_MSG_DISK_READ_OK:
    db "[] MBR: read ", 0
DBG_MSG_COLON:
    db ":", 0
DBG_MSG_TO:
    db " -> ", 0
%endif

; Memory for hex-string.
HEX_BUF:
    db "0x0000", 0

; Here we put boot drive number.
BOOT_DRIVE:
    db 0

; Disk Address Packet.
DAP:
    db 0x10 ; Packet size.
    db 0x00 ; Unused, must be zero.
_DAP_NUM_SECTORS:
    dw 0x00 ; Number of sectors to transfer.
_DAP_OFF_MEMORY_BUF:
    dw 0x00 ; Offset to memory buffer.
_DAP_SEG_MEMORY_BUF:
    dw 0x00 ; Segment of memory buffer.
_DAP_START_LBA:
    dq 0x01 ; Start Logical Block Address (LBA).

_partition_table equ 0x7c00 + 446
_boot16          equ 0x7c00 + 512
_boot32          equ 0x10000
