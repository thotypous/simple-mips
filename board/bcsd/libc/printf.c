#include <libc.h>
#include <drivers/console.h>

typedef struct Op {
    char *buf;
    int len;
    int (*full)(struct Op *op);
} Op;

typedef enum {
    OUTSIDE_FMT,
    INSIDE_FMT,
    FMT_PARSE_NUMBER,
} printf_state_t;

static int voprintf(Op *op, const char *format, va_list ap) {
    printf_state_t state = OUTSIDE_FMT;
    char *p = op->buf;
    int avail = op->len;
    int ret = 0;
    int fmtn = 0;
    int fill = ' ';
    int c;
#define writechar(c)                 \
    {                                \
        *(p++) = (c);                \
        ret++;                       \
        if(--avail == 0) {           \
            if(!op->full(op))        \
                return ret;          \
            avail = op->len;         \
            p = op->buf;             \
        }                            \
    }
    while((c = *format) != 0) {
        if(state == OUTSIDE_FMT) {
            if(c == '%') {
                state = INSIDE_FMT;
                fmtn = 0;
            }
            else {
                writechar(c);
            }
            format++;
        }
        else if(state == INSIDE_FMT) {
            if(c == '%') {
                writechar('%');
                state = OUTSIDE_FMT;
                format++;
            }
            else if(isdigit(c)) {
                fmtn = 0;
                fill = (c == '0') ? '0' : ' ';
                state = FMT_PARSE_NUMBER;
            }
            else if(c == 'l') {
                /* ignore l modifier */
                format++;
            }
            else if(c == 'c') {
                int arg = va_arg(ap, int);
                writechar(arg);
                state = OUTSIDE_FMT;
                format++;
            }
            else if(c == 'd' || c == 'u') {
                int sigarg = va_arg(ap, int);
                unsigned int arg = sigarg;
                unsigned int tmp, div = 1;
                if(c == 'd' && sigarg < 0) {
                    fmtn--;
                    arg = -sigarg;
                }
                tmp = arg;
                if(tmp == 0)
                    fmtn--;
                while(1) {
                    tmp /= 10;
                    fmtn--;
                    if(tmp == 0)
                        break;
                    div *= 10;
                }
                while(fmtn-- > 0)
                    writechar(fill);
                if(c == 'd' && sigarg < 0)
                    writechar('-');
                while(div > 0) {
                    writechar('0'+((arg/div)%10));
                    div /= 10;
                }
                state = OUTSIDE_FMT;
                format++;
            }
            else if(c == 's') {
                char *arg = va_arg(ap, char*);
                int argch;
                if(fmtn > 0) {
                    char *tmp = arg;
                    while(*(tmp++))
                        fmtn--;
                    while(fmtn-- > 0)
                        writechar(' ');
                }
                while((argch = *(arg++)))
                    writechar(argch);
                state = OUTSIDE_FMT;
                format++;
            }
            else if(c == 'p' || c == 'x' || c == 'X') {
                unsigned int arg, tmp, shf = 0;
                int A = (c == 'X') ? 'A' : 'a';
                if(c == 'p') {
                    arg = (unsigned int)va_arg(ap, void*);
                    fmtn -= 2;
                }
                else {
                    arg = va_arg(ap, unsigned int);
                }
                tmp = arg;
                if(tmp == 0)
                    fmtn--;
                while(tmp > 0) {
                    tmp >>= 4;
                    shf  += 4;
                    fmtn--;
                }
                while(fmtn-- > 0)
                    writechar(fill);
                if(c == 'p') {
                    writechar('0');
                    writechar('x');
                }
                while(shf > 0) {
                    int dig = (arg >> (shf -= 4)) & 0xf;
                    if(dig < 10) {
                        writechar('0'+dig);
                    }
                    else {
                        writechar(A+dig-10);
                    }
                }
                state = OUTSIDE_FMT;
                format++;
            }
        }
        else if(state == FMT_PARSE_NUMBER) {
            if(isdigit(c)) {
                fmtn = (fmtn*10) + (c-'0');
                format++;
            }
            else {
                state = INSIDE_FMT;
            }
        }
    }
    *p = 0;
    return ret;
}

static int vprintf_full(struct Op *op) {
    op->buf[1023] = 0;
    console_write(op->buf);
    op->len = 1023;
    return 1;
}

int vprintf(const char *format, va_list ap) {
    static char buf[1024];
    Op op;
    int ret;
    
    buf[1023] = 0;
    op.buf = buf;
    op.len = 1023;
    op.full = vprintf_full;

    ret = voprintf(&op, format, ap);
    buf[1023] = 0;
    console_write(buf);

    return ret;
}

int printf(const char *format, ...) {
    va_list ap;
    int ret;
    va_start(ap, format);
    ret = vprintf(format, ap);
    va_end(ap);
    return ret;
}

static int vsnprintf_full(struct Op *op) {
    return 0;
}

int vsnprintf(char *str, size_t size, const char *format, va_list ap) {
    Op op;
    int ret;
    
    op.buf = str;
    op.len = size-1;
    op.full = vsnprintf_full;

    ret = voprintf(&op, format, ap);
    str[size-1] = 0;
    
    return ret;
}

int snprintf(char *str, size_t size, const char *format, ...) {
    va_list ap;
    int ret;
    va_start(ap, format);
    ret = vsnprintf(str, size, format, ap);
    va_end(ap);
    return ret;
}

int vsprintf(char *str, const char *format, va_list ap) {
    return vsnprintf(str, INT_MAX, format, ap);
}

int sprintf(char *str, const char *format, ...) {
    va_list ap;
    int ret;
    va_start(ap, format);
    ret = vsnprintf(str, INT_MAX, format, ap);
    va_end(ap);
    return ret;
}


