#!/usr/bin/env python
import sys, struct
load_at = 0x400
if len(sys.argv) == 2:
    load_at = int(sys.argv[1],16)
print '@%x'%(load_at>>2)
while True:
    data = sys.stdin.read(4)
    if len(data) != 4:
        break
    data, = struct.unpack('>I', data)
    print '%08x' % data
