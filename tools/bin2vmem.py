#!/usr/bin/env python
import sys, struct
print '@100'
while True:
    data = sys.stdin.read(4)
    if len(data) != 4:
        break
    data, = struct.unpack('>I', data)
    print '%08x' % data
