#!/bin/bash

set -ex

MAXN=${1:--1}
[[ "$MAXN" -lt 1 ]] && MAXN=3


LOGS='yum.log yum_err.log urlgrab.log'
FAILDIR="failed_$(date "+%y%m%d_%H_%M_%S")"

export URLGRABBER_DEBUG="1,urlgrab.log"

N=0
while [[ $N -lt $MAXN ]]; do
    rm -f $LOGS

    yum -d 10 --rpmverbosity=10 -y reinstall ipmitool 2>yum_err.log | tee yum.log || true
    if [[ "${PIPESTATUS[0]}" != "0" ]]; then
        mkdir -p $FAILDIR/$N;
        mv $LOGS $FAILDIR/$N/;
    fi

    N=$(( $N + 1 ))

    sleep 1
done

if [[ -d "$FAILDIR" ]]; then
    echo ""
    echo ""
    echo "==== THERE WERE SOME FAILURES: look in $FAILDIR ===="
    echo ""
    echo ""
else
    echo "==== Seems all went ok ===="
fi
