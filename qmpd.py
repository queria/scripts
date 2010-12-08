#! /usr/bin/env python
import dbus
import subprocess
from time import sleep

bus = dbus.SessionBus()

def connect():
    return bus.get_object('net.bitcheese.QMPDClient', '/MainApplication')

qmpd = None
try:
    qmpd = connect()
except dbus.exceptions.DBusException:
    subprocess.Popen('qmpdclient')
    #sleep(1)
    #try:
    #    qmpd = connect()
    #except dbus.exceptions.DBusException:
    #    pass

if qmpd:
    qmpd.toggleMainWindow()

