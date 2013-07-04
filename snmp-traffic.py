#!/usr/bin/env python

from __future__ import print_function
import os
import netsnmp
import sys
import time
import yaml


# to use create config file ~/.snmp-traffic.yaml with content like:
##> hosts:
##>     myswitch:
##>         host: 192.168.0.1
##>         version: 1
##>         community: public
##>         oid_base: .1.3.6.1.2.1.2.2.1
##>         oid_rx: 10
##>         oid_tx: 16
##>     mysecond:
##>         host: 192.168.0.2
##>         oid_base: .1.3.6.1.2.1.2.2.1
##>         oid_rx: 10
##>         oid_tx: 16
# ... those example oids are valid for Mikrotik SWOS 1.9
# and then call this script like:
##> $ ./snmp-traffic.py myswitch
# to quit use Ctrl+C etc

class TrafficRateReader:
    def __init__(self, host, version, community, oid_base, oid_rx, oid_tx):
        if not oid_base.startswith('.'):
            oid_base = '.' + oid_base

        self.oid = {'rx': '%s.%s' % (oid_base, oid_rx),
                    'tx': '%s.%s' % (oid_base, oid_tx)}
        self.last = {}
        self.diff = {}

        print('Connecting to %s v%s comm=%s' % (host, version, community))
        self.con = self.connect(host, version, community)
        # read current value
        for direction in self.oid.keys():
            self.last[direction] = self.get_values(self.oid[direction])

    def connect(self, host, version, community):
        return netsnmp.Session(
            DestHost=host,
            Version=version,
            Community=community)

    def port_count(self):
        key = self.last.keys()[0]
        return len(self.last[key])

    def __iter__(self):
        return self

    def next(self):
        for direction in self.oid.keys():
            new_vals = self.get_values(self.oid[direction])
            self.diff[direction] = self.diff_values(
                self.last[direction], new_vals)
            self.last[direction] = new_vals
        return self.diff

    def get_values(self, oid):
        mvars = netsnmp.VarList(netsnmp.Varbind(oid))
        return [int(v) for v in self.con.walk(mvars)]

    def diff_values(self, old, new):
        return [new[k] - v for k, v in enumerate(old)]


if __name__ == '__main__':
    with open(os.path.expanduser('~/.snmp-traffic.yaml')) as config_file:
        cfg = yaml.load(config_file)
    if len(sys.argv) < 2 or '--help' in sys.argv:
        print('Specify host to read information from.\n\n'
              'Currenty available (from ~/.snmp-traffic.yaml):')
        print(cfg['hosts'].keys())
        sys.exit(1)
    host_name = sys.argv[1]
    host_cfg = cfg['hosts'][host_name]
    host_cfg.pop('name', None)
    for k, v in {'version': 1, 'community': 'public'}.iteritems():
        host_cfg.setdefault(k, v)

    reader = TrafficRateReader(**host_cfg)

    # header
    for port_num in xrange(reader.port_count()):
        print('  %-13s' % ('== port%s ==' % (port_num+1)), end='')
    print('')

    # values
    for rate in reader:
        for port in zip(rate['rx'], rate['tx']):
            print(' %4d/%-4d kbps' % (port[0]/1024, port[1]/1024), end='')
        print('')
        time.sleep(1)

    print('DONE')
