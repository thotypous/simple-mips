#include <drivers/system.h>
#include <drivers/led.h>

static volatile int * const dev_pio_ledg = (int *)DEVADDR_PIO_LEDG;

void led_write(int n) {
    *dev_pio_ledg = n;
}

int led_read() {
    return *dev_pio_ledg;
}

