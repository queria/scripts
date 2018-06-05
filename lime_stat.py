#!/usr/bin/env python
from __future__ import print_function
import socket

srv = ("37.187.74.33", 27015)
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
## split first text fields up to last numbers list
rep = rep.split('\x00', 5)
## get list with numbers
nums = rep[-1]

keyvals_str = nums.split('@', 2)[1]
keyvals = {}
for entry_str in keyvals_str.split(','):
    entry = entry_str.split(':', 2)
    if (len(entry) != 2):
        print('Missmatching: %s' % entry_str)
    else:
        _k = entry[0].strip()
        _v = entry[1].strip()
        keyvals[_k] = _v

#print(keyvals)
#print(nums[0:30].encode('hex'))
#print(nums[0:30])
#
## hostname - players/maxplayers
print('%s - %s/%s' % (
    rep[0],
    keyvals['playersCount'],
    ord(nums[2])))
#
