#include <libc.h>
#include <drivers/console.h>
#include <drivers/keyboard.h>

void irqhandler(unsigned int mask) {
    if(mask & 0x01)
        keyb_irqhandler();
}

void keyb_callback(int ascii, int code, int isextended) {
    if(ascii == 'c' && (keyb_modifiers & KEYB_CTRL))
        emulate_sigint();
    else
        console_keyb(ascii, code, isextended);
}

int main() {
    lcd_init();
    keyb_init();
    asm("syscall 0x4"); /* IRQ enable */
    while(1);
    return 0;
}
