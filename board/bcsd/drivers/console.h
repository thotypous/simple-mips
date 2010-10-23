#ifndef LCD_H
#define LCD_H

void lcd_init();
void console_write(char *text);
void console_keyb(int ascii, int code, int isextended);
char *console_readline();

#endif
