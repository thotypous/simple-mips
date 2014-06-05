CC=mips-linux-gnu-gcc
AS=mips-linux-gnu-as
LD=mips-linux-gnu-ld
CFLAGS=-mips1 -mno-abicalls -fno-zero-initialized-in-bss -O2 -Wall -pipe
LDFLAGS=-T ldscript.x

OBJECTS=start.o main.o

QUARTUSPROJDIR=/home/paulo/MIPSboard
QUARTUSPROJNAME=MIPSboard

all: bootrom.hex

updatesof: bootrom.hex
	cp bootrom.hex $(QUARTUSPROJDIR)
	(cd $(QUARTUSPROJDIR) ; \
	 quartus_cdb --update_mif $(QUARTUSPROJNAME) ; \
	 quartus_asm $(QUARTUSPROJNAME) )

bootrom.hex: bootrom.bin
	./bin2hex.py < bootrom.bin > bootrom.hex

bootrom.bin: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o bootrom.bin

clean:
	rm -f $(OBJECTS) bootrom.bin bootrom.hex

