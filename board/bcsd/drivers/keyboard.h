#ifndef KEYBOARD_H
#define KEYBOARD_H

#define KEYB_CTRL  0x01
#define KEYB_ALT   0x02
#define KEYB_SHIFT 0x04
extern int keyb_modifiers;

void keyb_callback(int ascii, int code, int isextended);

int keyb_init();
void keyb_irqhandler();
int keyb_write_data_byte(int byte);
int keyb_wait_for_ack(int timeout);
int keyb_write_data_byte_with_ack(int byte, int timeout);
int keyb_read_data_byte();
int keyb_read_data_byte_timeout(int timeout);
void keyb_clear_fifo();

#endif
