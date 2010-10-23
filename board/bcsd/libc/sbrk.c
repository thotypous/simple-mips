/* sbrk.c -- allocate memory dynamically.
 * 
 * Copyright (c) 1995,1996 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#include <libc.h>

static char *heap_ptr = (char *)0x1000000;
static char *heap_end = (char *)0x2000000;

void *sbrk(int nbytes) {
    char *base;

    base = heap_ptr;
    heap_ptr += nbytes;
    
    if(heap_ptr > heap_end) {
        heap_ptr -= nbytes;
        errno = ENOMEM;
        return ((void *)-1);
    }

    return (void *)base;
}
