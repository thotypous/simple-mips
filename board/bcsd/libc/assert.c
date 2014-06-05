#include <libc.h>

void __assert_func(const char *file, int line, const char *msg) {
    printf("Assert failed: %s:%d: %s\n", file, line, msg);
    exit(1);
}

