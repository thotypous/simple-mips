#include <libc.h>

static sighandler_t cur_sighandler = NULL;

sighandler_t signal(int signum, sighandler_t handler) {
    sighandler_t old_sighandler = cur_sighandler;
    cur_sighandler = handler;
    return old_sighandler;
}

void emulate_sigint(void) {
    if(cur_sighandler != NULL)
        cur_sighandler(SIGINT);
}

