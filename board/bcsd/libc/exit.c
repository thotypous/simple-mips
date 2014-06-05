#include <libc.h>

void exit(int status) {
    printf("exit(%d) called\n", status);
    while(1);
}
