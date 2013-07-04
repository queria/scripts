#!/bin/bash

# use configuration given as argument
CONFIG=$1

if ! which xrandr &> /dev/null; then
    echo "No xrandr command available ... you have to fix it."
    exit 1
fi

# if specified, otherwise try autodetection
if [[ -z "$CONFIG" ]]; then
    if xrandr -q | grep "HDMI3 connected"; then
        CONFIG=work
    elif [[ $(xrandr -q | grep " connected "|wc -l) == 1 ]]; then
        CONFIG=default
    fi
    # place your autodetection here

    #echo "Autodetected monitor layout: $CONFIG"
fi

# always first switch back to default
xrandr --output HDMI3 --off --output LVDS1 --auto --rotate normal --reflect normal --primary

case $CONFIG in
    work)
        xrandr --output HDMI3 --auto --above LVDS1 --output LVDS1 --auto --primary
        ;;
    default)
        # use just display of nb
        #xrandr --output HDMI3 --off --output LVDS1 --auto --rotate normal --reflect normal --primary
        # do nothing as we should be in the default now
        ;;
    -h|--help|help|*)
        echo "Usage:"
        echo "$0 [work | default]" # list possible configurations here
        ;;
esac

