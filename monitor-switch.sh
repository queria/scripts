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

# first everything off to clean possible manual changes,

# also workarounds issue with razor-qt WM, which may calculate positions
# incorrectly after display is switched
# ~ https://github.com/Razor-qt/razor-qt/issues/612

for DISP in $(xrandr |sed -n '/connect/s/ \(dis\)\?connected.*$//p'); do
    xrandr --output $DISP --off
done

# always switch back to default
xrandr --output LVDS1 --auto --rotate normal --reflect normal --primary

case $CONFIG in
    work)
        xrandr --output HDMI3 --auto --above LVDS1 --output LVDS1 --auto --primary
        ;;
    present)
        xrandr --output VGA1 --auto --leftof LVDS1 --output LVDS1 --auto --primary
        ;;
    present-mirror)
        xrandr --output VGA1 --same-as LVDS1
    #    xrandr --output VGA1 --off --output LVDS1 --auto --rotate normal --reflect normal --primary
        ;;
    small)
        xrandr --output LVDS1 --scale 0.67x0.67
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

