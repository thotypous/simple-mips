/* Simple ld script for the MIPS emulator */
 
/* Based on
 * ld.script for compressed kernel support of MIPS
 * Copyright (C) 2009 Lemote Inc.
 * Author: Wu Zhangjin <wuzj@lemote.com>
 */

OUTPUT_FORMAT(binary)
OUTPUT_ARCH(mips)
ENTRY(__start)
SEARCH_DIR("tools")
STARTUP(start.o)
SECTIONS
{
    . = 0x400;
    /* read-only */
    _text = .;  /* Text and read-only data */
    .text   : {
        _ftext = . ;
        *(.text)
        *(.rodata)
    } = 0
    _etext = .; /* End of text section */

    /* writable */
    .data   : { /* Data */
        _fdata = . ;
        *(.data)
        /* Put the compressed image here, so bss is on the end. */
        __image_begin = .;
        *(.image)
        __image_end = .;
        CONSTRUCTORS
    }
    .sdata  : { *(.sdata) }
    . = ALIGN(4);
    _edata  =  .;   /* End of data section */

    /* BSS */
    __bss_start = .;
    _fbss = .;
    .sbss   : { *(.sbss) *(.scommon) }
    .bss    : {
        *(.dynbss)
        *(.bss)
        *(COMMON)
    }
    .  = ALIGN(4);
    _end = . ;

    /* These are needed for ELF backends which have not yet been converted
     * to the new style linker.  */

    .stab 0 : { *(.stab) }
    .stabstr 0 : { *(.stabstr) }

    /* These must appear regardless of  .  */
    .gptab.sdata : { *(.gptab.data) *(.gptab.sdata) }
    .gptab.sbss : { *(.gptab.bss) *(.gptab.sbss) }

    /* Sections to be discarded */
    /DISCARD/   : {
        *(.MIPS.options)
        *(.options)
        *(.pdr)
        *(.reginfo)
        *(.comment)
        *(.note)
    }
}
