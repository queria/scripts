#!/usr/bin/env python
from __future__ import print_function
import socket

srv = ("90.176.152.68", 28015)
query = "\xFF\xFF\xFF\xFF\x54Source Engine Query\x00"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    sock.sendto(query, srv)
    rep = sock.recvfrom(4096)
except:
    sock.close()
    raise

# strip first \xff's
rep = rep[0][6:]
# split first text fields up to last numbers list
rep = rep.split('\x00', 5)
# get list with numbers
nums = rep[5]

# hostname - players/maxplayers
print('%s - %d/%d' % (
    rep[0],
    ord(nums[1]),
    ord(nums[2])))
