#!/bin/bash

FREQ=$(( 30 * 60 ))
HB=$(( $FREQ + 120 ))

#rrdtool create net.rrd \
#    --step $FREQ \
#    DS:ping-gsg:GAUGE:$HB:0:10 \
#    DS:ping-pub:GAUGE:$HB:0:100 \
#    RRA:LAST:0:1:672

cd /var/log/check-gsg/

    #-s 'end-30m' \
    #-e 'now' \
    #-u 100 \
    #-s 'end-300m' \
rrdtool graph net2.png \
    -s 'now-7day' \
    -e 'now-1sec' \
    -w '1280' -h '768' \
    -t 'ping' \
    'DEF:gsg=net.rrd:ping-gsg:LAST' \
    'CDEF:gsg_clean=gsg,UN,-1,gsg,IF' \
    'DEF:pub=net.rrd:ping-pub:LAST' \
    'CDEF:pub_clean=pub,UN,-1,pub,IF' \
    'LINE1:gsg_clean#0000FF' \
    'LINE2:pub_clean#FF0000'
    #'CDEF:user_clean=user_avg,UN,0,user_avg,IF' \
    #'DEF:system_avg=cpu-system.rrd:value:AVERAGE' \
    #'CDEF:system_clean=system_avg,UN,0,system_avg,IF' \
    #'CDEF:user_stack=system_clean,user_clean,+' \
    #'AREA:user_clean#FFF000:user' \
    #'AREA:system_clean#FF0000:system' \
    #'LINE1:user_clean#FF0000'
