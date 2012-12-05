#!/bin/bash

VLCARGS="-I rc --rc-fake-tty"
VLCARGS="$VLCARGS --aout adummy"
VLCARGS="$VLCARGS --vout vdummy"

for F in "$@";
do
    echo "|| $F";
    (sleep 1; echo info; echo quit)|vlc $VLCARGS $F 2>&1;
done | grep "|"

