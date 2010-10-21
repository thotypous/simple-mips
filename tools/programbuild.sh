#!/bin/sh
#export PATH=$PATH:/opt/mipstools/bin
#mipseb-netbsdelf-pcc -O2 -c program.c
#mipseb-netbsdelf-ld -T /opt/mipstools/mipseb-netbsdelf/lib/ldscripts/emulator.x program.o -o program.bin
mips-linux-gnu-gcc -mips1 -mno-abicalls -mno-xgot -O2 -Wall -c program.c
mips-linux-gnu-ld -T tools/emulator.x program.o -o program.bin
tools/bin2vmem.py < program.bin > program.mem
