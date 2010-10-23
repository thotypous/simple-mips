#include "system.h"
#include "keyboard.h"
#include "lcd.h"
#include "led.h"

static volatile int * const dev_lcd = (int *)DEVADDR_LCD;

static char console_out_circbuf[512][16] = {{0}};
static int console_out_circbuf_pos = 0;
static int console_out_circbuf_disp = 0;

static char console_in_buf[5120] = {0};
static int console_in_buf_disp = 0;
static int lcd_cursor_pos = 0;

static void delay() {
    int i;
    for(i = 0; i < 10000; i++)
        asm("nop");
}

static void lcd_write_cmd(int cmd) {
    dev_lcd[0] = cmd;
    delay();
}

static void lcd_write_data(int data) {
    /* The LCD display doesn't support these ASCII characters O.o */
    if(data == '\\') data = 0xa4;
    if(data == '~' ) data = 0xe8;
    /* Write the data */
    dev_lcd[2] = data;
    delay();
}

void lcd_init() {
    /* Function Set: Set the interface data length to 8 bits
     * and select 2-line display and 5x7-dot character font.
     */
    lcd_write_cmd(0x38);  /* 00111000 */
    /* Display ON/OFF Control: Set display ON, cursor ON
     * and blink OFF.
     */
    lcd_write_cmd(0x0E);  /* 00001110 */
    /* Clear Display */
    lcd_write_cmd(0x01);  /* 00000001 */
    /* Entry Mode Set: Set mode to increment the address by
     * one and to shift cursor to the right when writing
     * characters to the internal RAM.
     */
    lcd_write_cmd(0x06);  /* 00000110 */
    /* Cursor Home: Returns both cursor and display to
     * original position.
     */
    lcd_write_cmd(0x02);  /* 00000010 */
    lcd_cursor_pos = 0;
}

static void lcd_ddram_addr(int line, int col) {
    const int pos = (line ? 0x40 : 0x00) + col;
    lcd_write_cmd(0x80 | pos);
}

static void console_render_in_buf() {
    int i, j;
    lcd_ddram_addr(0, 0);
    for(i = console_in_buf_disp, j = 0; j < 16 && i < 5120 && console_in_buf[i]; i++, j++)
        lcd_write_data(console_in_buf[i]);
    for(; j < 16; j++)
        lcd_write_data(' ');
    lcd_ddram_addr(0, lcd_cursor_pos);
}

static void console_render_out_circbuf() {
    const int i = console_out_circbuf_disp;
    int j;
    lcd_ddram_addr(1, 0);
    for(j = 0; j < 16 && console_out_circbuf[i][j]; j++)
        lcd_write_data(console_out_circbuf[i][j]);
    for(; j < 16; j++)
        lcd_write_data(' ');
    lcd_ddram_addr(0, lcd_cursor_pos);
}

static void console_move_cursor(int dir) {
    lcd_cursor_pos += dir;
    if(lcd_cursor_pos < 0) {
        if(console_in_buf_disp < 8) {
            console_in_buf_disp = 0;
            lcd_cursor_pos = 0;
        }
        else {
            console_in_buf_disp -= 8;
            lcd_cursor_pos += 8;
        }
        console_render_in_buf();
    }
    else if(lcd_cursor_pos > 15) {
        if(console_in_buf_disp > 5096)
            lcd_cursor_pos = 15;
        else {
            console_in_buf_disp += 8;
            lcd_cursor_pos -= 8;
            console_render_in_buf();
        }
    }
    lcd_ddram_addr(0, lcd_cursor_pos);
}

static void console_type_char(int ascii) {
    int i = console_in_buf_disp+lcd_cursor_pos;
    if(console_in_buf[i]) {
        /* insert between already typed text */
        /* shift text to the right */
        for(; i < 5118 && console_in_buf[i]; i++);
        for(; i >= console_in_buf_disp+lcd_cursor_pos; i--)
            console_in_buf[i+1] = console_in_buf[i];
        console_in_buf[console_in_buf_disp+lcd_cursor_pos] = ascii;
        console_render_in_buf();
    }
    else {
        lcd_write_data(ascii);
        console_in_buf[i++] = ascii;
        if(i < 5120)
            console_in_buf[i] = 0;
    }
    console_move_cursor(1);
}

static void console_delete_char(int pos) {
    int i;
    if(pos < 0 || pos > 5119)
        return;
    for(i = pos; i < 5119 && console_in_buf[i]; i++)
        console_in_buf[i] = console_in_buf[i+1];
    if(i == 5119)
        console_in_buf[i] = 0;
    console_render_in_buf();
}

void console_write(char *text, int breakline) {
    int j, i = console_out_circbuf_pos;
    for(j = 0; j < 16 && console_out_circbuf[i][j]; j++);
    while(1) {
        if((j == 16) || (*text == '\n')) {
            i = (i + 1) & 0x1ff;
            j = 0;
        }
        if(*text != '\n') {
            console_out_circbuf[i][j] = *text;
            j++;
        }
        if(*text == 0)
            break;
        text++;
    }
    console_out_circbuf_disp = i;
    if(breakline)
        i = (i + 1) & 0x1ff;
    console_out_circbuf_pos = i;
    console_render_out_circbuf();
}

void console_keyb(int ascii, int code, int isextended) {
    if(ascii) {
        console_type_char(ascii);
    }
    else if( isextended && code == 0x6B) {
        /* left arrow */
        console_move_cursor(-1);
    }
    else if( isextended && code == 0x74) {
        /* right arrow */
        if(console_in_buf[console_in_buf_disp+lcd_cursor_pos])
            console_move_cursor(1);
    }
    else if( isextended && code == 0x75) {
        /* up arrow */
        console_out_circbuf_disp--;
        console_out_circbuf_disp &= 0x1ff;
        console_render_out_circbuf();
    }
    else if( isextended && code == 0x72) {
        /* down arrow */
        if(keyb_modifiers & KEYB_CTRL) {
            console_out_circbuf_disp = console_out_circbuf_pos;
        }
        else {
            console_out_circbuf_disp++;
            console_out_circbuf_disp &= 0x1ff;
        }
        console_render_out_circbuf();
    }
    else if(!isextended && code == 0x66) {
        /* backspace */
        console_delete_char(console_in_buf_disp+lcd_cursor_pos-1);
        console_move_cursor(-1);
    }
    else if( isextended && code == 0x71) {
        /* delete */
        if(keyb_modifiers & KEYB_CTRL) {
            console_in_buf_disp = 0;
            lcd_cursor_pos = 0;
            console_in_buf[0] = 0;
            console_render_in_buf();
        }
        else {
            console_delete_char(console_in_buf_disp+lcd_cursor_pos);
        }
    }
    else if( isextended && code == 0x6C) {
        /* home */
        console_in_buf_disp = 0;
        lcd_cursor_pos = 0;
        console_render_in_buf();
    }
    else if( isextended && code == 0x69) {
        int i;
        for(i = 0; i < 5119 && console_in_buf[i]; i++);
        if(i < 8) {
            console_in_buf_disp = 0;
            lcd_cursor_pos = i;
        }
        else {
            console_in_buf_disp = i-8;
            lcd_cursor_pos = 8;
        }
        console_render_in_buf();
    }
    else if(code == 0x5A) {
        /* enter */
        console_in_buf[5119] = 0;
        console_cmd_callback(console_in_buf);
        console_in_buf_disp = 0;
        lcd_cursor_pos = 0;
        console_in_buf[0] = 0;
        console_render_in_buf();
    }
}

