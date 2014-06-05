    .section .text.reset
    .globl __start
    .ent __start
__start:
    .set noreorder
    jal main
    lui $sp, 0x100
    .set reorder
    .end __start
    .size __start,.-__start

