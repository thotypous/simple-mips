#include "system.h"
#include "keyboard.h"

static volatile unsigned int * const dev_keyb = (unsigned int *)DEVADDR_PS2_KEYB;
#define keyb_read_data()       (dev_keyb[0])
#define keyb_read_control()    (dev_keyb[1])
#define keyb_send_command(cmd) (dev_keyb[0]=(cmd))

#define keyb_data_available(data) ((data)>>16)
#define keyb_data_in_fifo(data)   ((data)&0xff)

#define CE_BIT (1<<10)
#define RI_BIT (1<< 8)
#define RE_BIT (1    )

#define PS2_ACK  0xFA

static const char keyb_asciimap_sh0[] = {
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,'\'', 0,
  0,  0,  0,  0,  0,'q','1',  0,  0,  0,'z','s','a','w','2',  0,
  0,'c','x','d','e','4','3',  0,  0,' ','v','f','t','r','5',  0,
  0,'n','b','h','g','y','6',  0,  0,  0,'m','j','u','7','8',  0,
  0,',','k','i','o','0','9',  0,  0,'.',';','l','c','p','-',  0,
  0,'/','~',  0,'\'','=', 0,  0,  0,  0,  0,'[',  0,']',  0,  0,
  0,'\\', 0,  0,  0,  0,  0,  0,  0,'1',  0,'4','7','.',  0,  0,
'0',',','2','5','6','8',  0,  0,  0,'+','3','-','*','9',  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
};

static const char keyb_asciimap_sh1[] = {
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,'"',  0,
  0,  0,  0,  0,  0,'Q','!',  0,  0,  0,'Z','S','A','W','@',  0,
  0,'C','X','D','E','$','#',  0,  0,' ','V','F','T','R','%',  0,
  0,'N','B','H','G','Y','"',  0,  0,  0,'M','J','U','&','*',  0,
  0,'<','K','I','O',')','(',  0,  0,'>',':','L','C','P','_',  0,
  0,'?','^',  0,'`','+',  0,  0,  0,  0,  0,'{',  0,'}',  0,  0,
  0,'|',  0,  0,  0,  0,  0,  0,  0,'1',  0,'4','7','.',  0,  0,
'0',',','2','5','6','8',  0,  0,  0,'+','3','-','*','9',  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
};

typedef enum {
    IDLE,
    WAIT_BREAK,
    WAIT_EXTENDED,
    WAIT_BREAK_EXTENDED
} keyb_state_t;

static keyb_state_t keyb_state = IDLE;
int keyb_modifiers = 0;

void keyb_irqhandler() {
    int byte;
    if((byte = keyb_read_data_byte()) < 0)
        return;
    if(keyb_state == IDLE) {
        if(byte == 0xF0)
            keyb_state = WAIT_BREAK;
        else if(byte == 0xE0)
            keyb_state = WAIT_EXTENDED;
        else {
            if(byte == 0x14)
                keyb_modifiers |= KEYB_CTRL;
            else if(byte == 0x11)
                keyb_modifiers |= KEYB_ALT;
            else if(byte == 0x12)
                keyb_modifiers |= KEYB_SHIFT;
            else {
                if(keyb_modifiers & KEYB_SHIFT)
                    keyb_callback(keyb_asciimap_sh1[byte], byte, 0);
                else
                    keyb_callback(keyb_asciimap_sh0[byte], byte, 0);
            }
        }
    }
    else if(keyb_state == WAIT_EXTENDED) {
        if(byte == 0xF0)
            keyb_state = WAIT_BREAK_EXTENDED;
        else {
            if(byte == 0x4A)
                keyb_callback('/', 0x4A, 1);
            else
                keyb_callback(0, byte, 1);
            keyb_state = IDLE;
        }
    }
    else if(keyb_state == WAIT_BREAK) {
        if(byte == 0x14)
            keyb_modifiers &= ~KEYB_CTRL;
        else if(byte == 0x11)
            keyb_modifiers &= ~KEYB_ALT;
        else if(byte == 0x12)
            keyb_modifiers &= ~KEYB_SHIFT;
        keyb_state = IDLE;
    }
    else if(keyb_state == WAIT_BREAK_EXTENDED) {
        keyb_state = IDLE;
    }
}

int keyb_init() {
    if(keyb_write_data_byte_with_ack(0xFF, 0x200000) < 0)
        return -1;
    if(keyb_read_data_byte_timeout(0x200000) != 0xAA)
        return -1;
    keyb_state = IDLE;
    dev_keyb[1] = 1;  /* enable interrupt */
    return 0;
}

int keyb_write_data_byte(int byte) {
    keyb_send_command(byte);
    if(keyb_read_control() & CE_BIT) {
        dev_keyb[1] = 1;  /* clear CE_BIT (hack) */
        return -1;
    }
    return 0;
}

int keyb_wait_for_ack(int timeout) {
    int byte;
    while(1) {
        byte = keyb_read_data_byte_timeout(timeout);
        if(byte < 0)
            return byte;
        if(byte == PS2_ACK)
            return 0;
    }
    return -1;
}

int keyb_write_data_byte_with_ack(int byte, int timeout) {
    if(keyb_write_data_byte(byte) < 0)
        return -1;
    return keyb_wait_for_ack(timeout);
}

int keyb_read_data_byte() {
    unsigned int data = keyb_read_data();
    if(keyb_data_available(data))
        return keyb_data_in_fifo(data);
    return -1;
}

int keyb_read_data_byte_timeout(int timeout) {
    int byte;
    while(timeout--) {
        byte = keyb_read_data_byte();
        if(byte >= 0)
            return byte;
    }
    return -1;
}

void keyb_clear_fifo() {
    unsigned int data;
    do {
        data = keyb_read_data();
    } while(keyb_data_available(data));
}

