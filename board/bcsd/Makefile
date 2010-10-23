CC=mips-linux-gnu-gcc
AS=mips-linux-gnu-as
LD=mips-linux-gnu-ld
CFLAGS=-mips1 -mno-abicalls -fno-zero-initialized-in-bss -O2 -Wall -pipe
LDFLAGS=-T ldscript.x

OBJECTS=asm/irqhandler.o asm/start.o drivers/keyboard.o drivers/lcd.o drivers/led.o main.o

all: bcsd.bin

bcsd.bin: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o bcsd.bin  

clean:
	rm -f $(OBJECTS) bcsd.bin
