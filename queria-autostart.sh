#!/bin/bash

[[ -f /usr/share/X11/xkb/symbols/vok ]] && setxkbmap vok
which monitor-switch.sh &>/dev/null && monitor-switch.sh
which xosd-sysmon &> /dev/null && xosd-sysmon &

