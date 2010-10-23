#ifndef LIBC_H
#define LIBC_H

#include <stdarg.h>

#define NULL ((void *)0)

#define INT_MAX 0x7fffffff

extern int errno;
#define ENOMEM 12
#define EINTR  4

#define SIGINT 2
typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
void emulate_sigint(void);

#define assert(__e) ((__e) ? (void)0 : __assert_func (__FILE__, __LINE__, #__e))

void __assert_func(const char *file, int line, const char *msg);
void exit(int status);

typedef unsigned int size_t;
typedef int ptrdiff_t;

void *sbrk(int increment);
void *malloc(size_t size);
void free(void *ptr);

void *memset(void *s, int c, size_t n);
void *memcpy(void *dest, const void *src, size_t n);
void *memmove(void *dest, const void *src, size_t n);
size_t strlen(const char *s);
char *strcpy(char *dest, const char *src);
char *strcat(char *dest, const char *src);
int strcmp(const char *s1, const char *s2);

int putchar(int c);
int getchar(void);
int printf(const char *format, ...);
int vprintf(const char *format, va_list ap);
int sprintf(char *str, const char *format, ...);

extern const char *__ctype_ptr__;

#define _U  01
#define _L  02
#define _N  04
#define _S  010
#define _P  020
#define _C  040
#define _X  0100
#define _B  0200

#define __ctype_lookup(__c) ((__ctype_ptr__+sizeof(""[__c]))[(int)(__c)])
#define isalpha(__c)    (__ctype_lookup(__c)&(_U|_L))
#define isupper(__c)    ((__ctype_lookup(__c)&(_U|_L))==_U)
#define islower(__c)    ((__ctype_lookup(__c)&(_U|_L))==_L)
#define isdigit(__c)    (__ctype_lookup(__c)&_N)
#define isxdigit(__c)   (__ctype_lookup(__c)&(_X|_N))
#define isspace(__c)    (__ctype_lookup(__c)&_S)
#define ispunct(__c)    (__ctype_lookup(__c)&_P)
#define isalnum(__c)    (__ctype_lookup(__c)&(_U|_L|_N))
#define isprint(__c)    (__ctype_lookup(__c)&(_P|_U|_L|_N|_B))
#define isgraph(__c)    (__ctype_lookup(__c)&(_P|_U|_L|_N))
#define iscntrl(__c)    (__ctype_lookup(__c)&_C)

#endif
