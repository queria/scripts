#!/usr/bin/env python3
### remove number 3 ^^^ from the end for python 2.x
import os
import json
import time
try:
    # for python 3:
    from urllib.request import urlopen
except ImportError:
    # for python 2:
    from urllib2 import urlopen

# ------------------------

feed_url = 'http://ipv6.he.net/exhaustionFeed.php?platform=json'
feed_cache = '/tmp/ipv6he_stats.cache'
cache_timeout = 1330 # minutes

# ------------------------

def print_rir(data, name):
    print(" {0}: {1:,} - {2}%".format(
        name,
        int(data[name.lower()+'24s']),
        data[name.lower()+'Percent']
        ))

def print_results(data):
    print('--- IPv4/6 Statistics ---')
    print('RIR v4 /24s Left:')
    for rir in ('AfriNIC', 'APNIC', 'ARIN', 'LACNIC', 'RIPE'):
        print_rir(data, rir)
    print('ASNs: {0}/{1}\nGlues: {2}\nDomains: {3:,}\n0Day: {4}'.format(
        data['v6ASNs'], data['totalASNs'],
        data['v6NS'],
        int(data['v6Domains']),
        data['exhaustionDateIPv4Depletion']
        ))

def get_data(feed_url, feed_cache, cache_timeout):
    cache_timeout = 60 * 10
    data = None
    try:
        if ((os.stat(feed_cache).st_mtime + cache_timeout)
                >= time.time()):
            with open(feed_cache, 'r') as cache:
                data = json.load(cache)
    except (OSError, ValueError) as e:
        pass

    if not data:
        feed_source = urlopen(feed_url).read().decode('utf-8')
        with open(feed_cache, 'w') as cache:
            cache.write(feed_source)
        data = json.loads(feed_source)

    return data

if __name__ == '__main__':
    print_results(get_data(feed_url, feed_cache, cache_timeout))

