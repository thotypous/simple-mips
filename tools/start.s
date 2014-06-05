    .text
    .globl __start
    .ent __start
__start:
    .set noreorder
    jal main
    lui $sp, 0x100
    syscall 0
    .set reorder
    .end __start
    .size __start,.-__start

