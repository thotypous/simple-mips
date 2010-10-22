#!/bin/sh
rm -f *.o bootrom.hex bootrom.bin
for x in *.s *.c; do mips-linux-gnu-gcc -mips1 -mno-abicalls -mno-xgot -fno-zero-initialized-in-bss -O2 -Wall -c $x; done
mips-linux-gnu-ld -T ldscript.x -o bootrom.bin *.o
./bin2hex.py < bootrom.bin > bootrom.hex
