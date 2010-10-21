#!/usr/bin/env python
import sys, struct
def main():
    addr = 0
    memsize = 0x800
    while addr < memsize:
        data = sys.stdin.read(4)
        if len(data) == 4:
            data, = struct.unpack('>I', data)
        else:
            data = 0
        cksum = 0x04
        for i in range(0,16,8): cksum = (cksum + ((addr >> i) & 0xff)) & 0xff;
        for i in range(0,32,8): cksum = (cksum + ((data >> i) & 0xff)) & 0xff;
        cksum = (0x100 - cksum) & 0xff
        print ':04%04X00%08X%02X' % (addr, data, cksum)
        addr += 1
    print ':00000001ff' # end
try:
    import psyco
    psyco.full()
except: pass
main()
