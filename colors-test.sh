#!/bin/bash

MSG="$*"
[[ -z "$MSG" ]] && read -t 10 -p "Type message or press enter" MSG
[[ -z "$MSG" ]] && MSG="test message"
        #echo -e "$C$CTP-$CLR 〒review/afazekas/unify-wait\033[00m";
for CLR in $(seq 40); do
    for CTP in 0 1; do
        C="\033[0${CTP};${CLR}m";
        echo -e "$C$CTP-$CLR $MSG\033[00m";
    done
done
