#!/bin/bash

[[ -f /usr/share/X11/xkb/symbols/vok ]] && setxkbmap vok
which xosd-sysmon &> /dev/null && xosd-sysmon &

