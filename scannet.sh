#!/bin/bash

if [[ "$1" == "--help" ]]; then
    echo "Usage:"
    echo " $0 eth0 192.168.0.88"
    echo ""
    echo "This will assign given ip on the ifc"
    echo "and try to scan whole C subnet (/24)"
    exit 0
fi

DEV="$1"
IP="$2"

MASK="24"

NET_ADD="${IP%.*}.0/${MASK}"
NET_BRD="${IP%.*}.255"

ip a add $IP/$MASK dev $DEV 
ping -c2 -b "${NET_BRD}" &
nmap -sP "${NET_ADD}" &
wait
ip a del $IP/$MASK dev $DEV

