#!/bin/bash

xset dpms 0 0 0
[[ -e "$HOME/all" && ! -e "$HOME/all/tmp" ]] && (mkdir /tmp/ps_tmp && ln -s /tmp/ps_tmp "$HOME/all/tmp")

[[ -f /usr/share/X11/xkb/symbols/vok ]] && setxkbmap vok

TPNAME=$(xinput list|grep 'TrackPoint'|sed "s/^\W*\(\w.*\w\)\W*id=.*$/\1/")
if [[ ! -z "$TPNAME" ]] && xinput list-props "$TPNAME" |& grep -q 'Evdev Wheel Emul'; then
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Timeout' 300
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Button' 2
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation' 1
    xinput set-prop "$TPNAME" 'Evdev Wheel Emulation Axes' 6 7 4 5
    xinput set-prop "$TPNAME" 'Device Accel Profile' 3
    xinput set-prop "$TPNAME" 'Device Accel Velocity Scaling' 50
else
    TPNAME=$(xinput list|grep 'Synaptics TouchPad'|sed "s/^\W*\(\w.*\w\)\W*id=.*$/\1/")
    if [[ ! -z "$TPNAME" ]]; then
        xinput set-prop "$TPNAME" 'Synaptics Tap Action' 0 0 0 0 1 3 0
    fi
fi

runcond() {
    if which $1 &> /dev/null; then
        "$@" &> /dev/null &
    fi
}

pulseaudio -D
urxvtd -f -o
runcond clipit
#runcond xosd-sysmon
runcond qslock-auto
#runcond qsrun
runcond dunst
runcond nm-applet
#runcond compton -b

wpsetters=feh fbsetbg -C $HOME/wallpaper.png
xset s off
