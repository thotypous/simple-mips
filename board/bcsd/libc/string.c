#include <libc.h>

void *memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    size_t i;
    for(i = 0; i < n; i++) {
        *p = c;
        p++;
    }
    return s;
}

void *memcpy(void *dest, const void *src, size_t n) {
    const unsigned char *srcp = (const unsigned char *)src;
    unsigned char *dstp = (unsigned char *)dest;
    size_t i;
    for(i = 0; i < n; i++) {
        *dstp = *srcp;
        srcp++;
        dstp++;
    }
    return dest;
}

void *memmove(void *dest, const void *src, size_t n) {
    unsigned char *dstp = (unsigned char *)dest;
    const unsigned char *srcp = (const unsigned char *)src;
    if(srcp < dstp && dstp < srcp + n) {
        srcp += n;
        dstp += n;
        while(n--)
            *--dstp = *--srcp;
    }
    else {
        while(n--)
            *dstp++ = *srcp++;
    }
    return dest;
}

size_t strlen(const char *s) {
    size_t len = 0;
    while(*s) {
        s++;
        len++;
    }
    return len;
}

char *strcpy(char *dest, const char *src) {
    char * const orig_dest = dest;
    while(*src) {
        *dest = *src;
        src++;
        dest++;
    }
    *dest = 0;
    return orig_dest;
}

char *strncpy(char *dest, const char *src, size_t n) {
    size_t i;
    for(i = 0; i < n && src[i] != 0; i++)
        dest[i] = src[i];
    for(; i < n; i++)
        dest[i] = 0;
    return dest;
}

char *strcat(char *dest, const char *src) {
    char * const orig_dest = dest;
    while(*dest)
        dest++;
    strcpy(dest, src);
    return orig_dest;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 != 0 && *s1 == *s2) {
        s1++;
        s2++;
    }
    return (*(unsigned char *)s1) - (*(unsigned char *)s2);
}

