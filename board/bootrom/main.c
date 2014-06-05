#include "system.h"

volatile unsigned int * const dev_pio_ledg = (unsigned int *)DEVADDR_PIO_LEDG;
volatile unsigned int * const dev_sd_clk   = (unsigned int *)DEVADDR_SD_CLK;
volatile unsigned int * const dev_sd_cmd   = (unsigned int *)DEVADDR_SD_CMD;
volatile unsigned int * const dev_sd_dat   = (unsigned int *)DEVADDR_SD_DAT;
volatile unsigned int * const dev_sd_dat3  = (unsigned int *)DEVADDR_SD_DAT3;

#define SD_CMD_IN    (dev_sd_cmd [1]=0)
#define SD_CMD_OUT   (dev_sd_cmd [1]=1)
#define SD_DAT_IN    (dev_sd_dat [1]=0)
#define SD_DAT_OUT   (dev_sd_dat [1]=1)
#define SD_DAT3_IN   (dev_sd_dat3[1]=0)
#define SD_DAT3_OUT  (dev_sd_dat3[1]=1)
#define SD_CMD_LOW   (dev_sd_cmd [0]=0)
#define SD_CMD_HIGH  (dev_sd_cmd [0]=1)
#define SD_DAT_LOW   (dev_sd_dat [0]=0)
#define SD_DAT_HIGH  (dev_sd_dat [0]=1)
#define SD_DAT3_LOW  (dev_sd_dat3[0]=0)
#define SD_DAT3_HIGH (dev_sd_dat3[0]=1)
#define SD_CLK_LOW   (dev_sd_clk [0]=0)
#define SD_CLK_HIGH  (dev_sd_clk [0]=1)
#define SD_TEST_CMD  (dev_sd_cmd [0]  )
#define SD_TEST_DAT  (dev_sd_dat [0]  )
#define SD_TEST_DAT3 (dev_sd_dat3[0]  )

int          * const response_buffer/*[ 20]*/ = (int          *)0x1000000;
int          * const cmd_buffer     /*[  5]*/ = (int          *)0x1000050;
unsigned char* const block_buffer   /*[512]*/ = (unsigned char*)0x1000064;

const int  cmd0 [5] = {0x40,0x00,0x00,0x00,0x00}; /* Reset SD Card */
const int  cmd55[5] = {0x77,0x00,0x00,0x00,0x00}; /* Next CMD is ASC */
const int  cmd2 [5] = {0x42,0x00,0x00,0x00,0x00}; /* Asks to send the CID numbers */
const int  cmd3 [5] = {0x43,0x00,0x00,0x00,0x00}; /* Send RCA */
const int  cmd7 [5] = {0x47,0x00,0x00,0x00,0x00}; /* Select one card, put it into Transfer State */
const int  cmd9 [5] = {0x49,0x00,0x00,0x00,0x00}; /* Ask send CSD */
const int  cmd10[5] = {0x4a,0x00,0x00,0x00,0x00}; /* Ask send CID */
const int  cmd16[5] = {0x50,0x00,0x00,0x02,0x00}; /* Select a block length */
const int  cmd17[5] = {0x51,0x00,0x00,0x00,0x00}; /* Read a single block */
const int acmd6 [5] = {0x46,0x00,0x00,0x00,0x02}; /* SET BUS WIDTH */
const int  cmd24[5] = {0x58,0x00,0x00,0x00,0x00}; /* Write a single block */
const int acmd41[5] = {0x69,0x0f,0xf0,0x00,0x00}; /* Active Card's ini process */
const int acmd42[5] = {0x6A,0x0f,0xf0,0x00,0x00}; /* Disable pull up on Dat3 */
const int acmd51[5] = {0x73,0x00,0x00,0x00,0x00}; /* Read SCR(Configuration Reg) */

static void delay() {
    int i;
    for(i = 0; i < 0x100000; i++)
        asm("nop");
}

static void Ncr() {
    SD_CMD_IN;
    SD_CLK_LOW;
    SD_CLK_HIGH;
    SD_CLK_LOW;
    SD_CLK_HIGH;
}

static void Ncc() {
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
    SD_CLK_LOW; SD_CLK_HIGH;
}

static void SD_cmd(const int *cmd) {
    int i, j;
    int b, crc = 0;
    SD_CMD_OUT;
    /* Send the cmd bytes */
    for(i = 0; i < 5; i++) {
        b = cmd[i];
        for(j = 0; j < 8; j++) {
            SD_CLK_LOW;
            if(b & 0x80)
                SD_CMD_HIGH;
            else
                SD_CMD_LOW;
            crc <<= 1;
            SD_CLK_HIGH;
            if((crc ^ b) & 0x80)
                crc ^= 0x09;
            b <<= 1;
        }
        crc &= 0x7f;
    }
    crc = (crc << 1) | 0x01;
    /* Send the CRC byte */
    for(j = 0; j < 8; j++) {
        SD_CLK_LOW;
        if(crc & 0x80)
            SD_CMD_HIGH;
        else
            SD_CMD_LOW;
        SD_CLK_HIGH;
        crc <<= 1;
    }
}

static int SD_read_response(int s) {
    int a=0, b=0, c=0, r=0, crc=0;
    int i=0, j=6, k;
    while(1) {
        SD_CLK_LOW;
        SD_CLK_HIGH;
        if(SD_TEST_CMD == 0)
            break;
        if(i++ > 100)
            return 2;
    }
    if(s == 2)
        j = 17;
    for(k = 0; k < j; k++) {
        c = 0;
        if(k > 0)
            b = response_buffer[k-1];
        for(i = 0; i < 8; i++) {
            SD_CLK_LOW;
            if(a) {
                c <<= 1;
            }
            else {
                i++;
                a = 1;
            }
            SD_CLK_HIGH;
            if(SD_TEST_CMD)
                c |= 0x01;
            if(k > 0) {
                crc <<= 1;
                if((crc ^ b) & 0x80)
                    crc ^= 0x09;
                b <<= 1;
                crc &= 0x7f;
            }
        }
        if(s == 3) {
            if(k == 1 && ((c & 0x80)==0))
                r = 1;
        }
        response_buffer[k] = c;
    }
    if(s == 1 || s == 6) {
        if(c != ((crc << 1) | 0x01))
            r = 2;
    }
    return r;
}

static int SD_init() {
    int i;
    
    SD_DAT3_OUT;
    SD_DAT3_HIGH;    
    for(i = 0; i < 20000; i++)
        asm("nop");

    SD_CMD_OUT;
    SD_DAT_IN;
    SD_CLK_HIGH;
    SD_CMD_HIGH;
    SD_DAT_LOW;

    for(i = 0; i < 40; i++);
        Ncr();
    SD_cmd(cmd0);

    do {
        for(i = 0; i < 40; i++)
            Ncc();
        SD_cmd(cmd55);
        Ncr();
        if(SD_read_response(1) > 1)
            return 0;
        Ncc();
        SD_cmd(acmd41);
        Ncr();
    } while(SD_read_response(3) == 1);

    Ncc();
    SD_cmd(cmd2);
    Ncr();
    if(SD_read_response(2) > 1)
        return 0;

    Ncc();
    SD_cmd(cmd3);
    Ncr();
    if(SD_read_response(6) > 1)
        return 0;

    Ncc();
    cmd_buffer[1] = response_buffer[1];
    cmd_buffer[2] = response_buffer[2];
    cmd_buffer[0] = cmd9[0];
    cmd_buffer[3] = cmd9[3];
    cmd_buffer[4] = cmd9[4];
    SD_cmd(cmd_buffer);
    Ncr();
    if(SD_read_response(2) > 1)
        return 0;

    Ncc();
    cmd_buffer[0] = cmd10[0];
    cmd_buffer[3] = cmd10[3];
    cmd_buffer[4] = cmd10[4];
    SD_cmd(cmd_buffer);
    Ncr();
    if(SD_read_response(2) > 1)
        return 0;

    Ncc();
    cmd_buffer[0] = cmd7[0];
    cmd_buffer[3] = cmd7[3];
    cmd_buffer[4] = cmd7[4];
    SD_cmd(cmd_buffer);
    Ncr();
    if(SD_read_response(1) > 1)
        return 0;

    Ncc();
    SD_cmd(cmd16);
    Ncr();
    if(SD_read_response(1) > 1)
        return 0;

    return 1;
}

static int SD_read(unsigned int block, unsigned int *dest) {
    int i, j, try=0;
    unsigned int c = 0;
    Ncc();
    cmd_buffer[0] = cmd17[0];
    cmd_buffer[1] = (block >> 15) & 0xff;
    cmd_buffer[2] = (block >>  7) & 0xff;
    cmd_buffer[3] = (block <<  1) & 0xff;
    cmd_buffer[4] = 0;
    SD_cmd(cmd_buffer);
    Ncr();
    while(1) {
        SD_CLK_LOW;
        SD_CLK_HIGH;
        if(SD_TEST_DAT == 0)
            break;
        if(try++ > 500000)
            return 0;
    }
    for(i = 0; i < 128; i++) {
        c = 0;
        for(j = 0; j < 32; j++) {
            SD_CLK_LOW;
            SD_CLK_HIGH;
            c <<= 1;
            if(SD_TEST_DAT)
                c |= 0x01;
        }
        *dest = c;
        dest++;
    }
    for(i = 0; i < 16; i++) {
        SD_CLK_LOW;
        SD_CLK_HIGH;
    }
    return 1;
}

int main() {
    unsigned int *data_dest = (unsigned int *)0x200;
    int part_offset, part_count;
    int i;

    /* Memory fill */
    for(i = 0; i < 256; i++) {
        *dev_pio_ledg = i;
        data_dest[i] = i;
    }
    /* Clear cache */
    asm("syscall 0x2\n\t"
        "nop\n\t"
        "nop\n\t"
        "nop\n\t");
    /* Memory test */
    for(i = 0; i < 256; i++) {
        *dev_pio_ledg = i;
        if(data_dest[i] != i) {
            *dev_pio_ledg = 0xAA;
            while(1);
        }
    }

    /* SD card boot sequence */
    while(1) {
        *dev_pio_ledg = 0x01;  /* Booted */

        while(!SD_init()) {
            *dev_pio_ledg ^= 0x02;
            delay();
        }
    
        *dev_pio_ledg = 0x03;  /* SD card detected */
    
        while(!SD_read(0, (unsigned int *)block_buffer)) {
            *dev_pio_ledg ^= 0x04;
            delay();
        }

        *dev_pio_ledg = 0x07;  /* First sector read */   

        /* Check MBR signature */
        if((block_buffer[0x1fe] != 0x55) || (block_buffer[0x1ff] != 0xAA)) {
            *dev_pio_ledg = 0xA0;
            delay(); delay();
            continue;
        }

        /* Check if the second partition is marked as bootable
         * and if it has the type 0xf0.
         */
        if((block_buffer[0x1ce] != 0x80) || (block_buffer[0x1d2] != 0xf0)) {
            *dev_pio_ledg = 0xA1;
            delay(); delay();
            continue;
        }

        /* Read partition offset and count in number of sectors */
        part_offset = (block_buffer[0x1d6]      ) |
                      (block_buffer[0x1d7] <<  8) |
                      (block_buffer[0x1d8] << 16) |
                      (block_buffer[0x1d9] << 24);
        part_count  = (block_buffer[0x1da]      ) |
                      (block_buffer[0x1db] <<  8) |
                      (block_buffer[0x1dc] << 16) |
                      (block_buffer[0x1dd] << 24);

        /* Assert part_count is less than 8 MB */
        if(part_count > 0x3fff) {
            *dev_pio_ledg = 0xA2;
            delay(); delay();
            continue;
        }

        /* Alright */
        break;
    }

    /* Start reading to 0x200 */
    while(part_count > 0) {
        if((part_count & 0x1f) == 0)
            *dev_pio_ledg ^= 0x08;

        SD_read(part_offset, data_dest);

        data_dest += 128;
        part_offset++;
        part_count--;
    }

    /* Read complete */
    *dev_pio_ledg = 0xff;
    delay();
    *dev_pio_ledg = 0x00;
    delay();
    *dev_pio_ledg = 0xff;
    delay();
    *dev_pio_ledg = 0x00;
    
    asm("syscall 0x2\n\t"
        "nop\n\t"
        "nop\n\t"
        "nop\n\t"
        "j 0x400\n\t"
        "nop");

    return 0;
}
