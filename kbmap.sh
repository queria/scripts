#!/bin/bash

current=$(setxkbmap -query|sed -rn 's/layout: +(.*)/\1/p')

next=vok
[[ $next = $current ]] && next=cz
setxkbmap $next
echo "layout: $next" | osd_cat -d1 -o100 -f "-*-fixed-*-*-*-*-*-140-*-*-*-*-*-*"
