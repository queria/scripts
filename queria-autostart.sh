#!/bin/bash

[[ -f /usr/share/X11/xkb/symbols/vok ]] && setxkbmap vok
which xosd-sysmon &> /dev/null && xosd-sysmon &
which parcellite &> /dev/null && parcellite &> /dev/null &
xset dpms 0 0 0
if which xautolock &> /dev/null && which i3lock &> /dev/null; then
    xautolock -time 3 -locker 'i3lock -p default -c ff2222 -d' &>/dev/null & 
fi

TPNAME=$(xinput list|grep 'TrackPoint'|sed "s/^\W*\(\w.*\w\)\W*id=.*$/\1/")
if [[ ! -z "$TPNAME" ]]; then
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Timeout' 300
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Button' 2
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation' 1
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Axes' 6 7 4 5
    xinput set-prop "$TPNAME" 'Device Accel Profile' 3
    xinput set-prop "$TPNAME" 'Device Accel Velocity Scaling' 50
fi

qsrun &

