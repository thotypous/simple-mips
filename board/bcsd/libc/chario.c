#include <libc.h>
#include <drivers/console.h>

int putchar(int c) {
    char buf[2];
    buf[0] = c;
    buf[1] = 0;
    console_write(buf);
    return c;
}

static char *getchar_buf = NULL;

int getchar(void) {
    int c;
    if(getchar_buf == NULL)
        getchar_buf = console_readline();
    c = *(getchar_buf++);
    if(c == '\n' || c == 0)
        getchar_buf = NULL;
    return c;
}

