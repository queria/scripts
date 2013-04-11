#!/bin/bash

[[ -f /usr/share/X11/xkb/symbols/vok ]] && setxkbmap vok
which xosd-sysmon &> /dev/null && xosd-sysmon &

TPNAME=$(xinput list|grep 'TrackPoint'|sed "s/^\W*\(\w.*\w\)\W*id=.*$/\1/")
if [[ ! -z "$TPNAME" ]]; then
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Timeout' 300
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Button' 2
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation' 1
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Axes' 6 7 4 5
fi

