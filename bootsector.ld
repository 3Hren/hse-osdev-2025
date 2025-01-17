ENTRY(_start)

SECTIONS {
    . = 0x7c00;

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }

    . = 0x7c00 + 510;

    .signature : {
        SHORT(0xaa55);
    }
}
