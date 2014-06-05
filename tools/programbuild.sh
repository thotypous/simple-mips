#!/bin/sh
mips-linux-gnu-gcc -mips1 -mno-abicalls -mno-xgot -O2 -fno-zero-initialized-in-bss -Wall -c program.c
mips-linux-gnu-ld -T tools/emulator.x program.o -o program.bin
tools/bin2vmem.py < program.bin > program.mem
