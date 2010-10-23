#ifndef LCD_H
#define LCD_H

void console_cmd_callback(char *cmd);

void lcd_init();
void console_write(char *text, int breakline);
void console_keyb(int ascii, int code, int isextended); 

#endif
