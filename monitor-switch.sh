#!/bin/bash

SAFEONLY=false
if [[ "$1" = "--safe" ]]; then
    SAFEONLY=true
    shift
fi

if ! which xrandr &> /dev/null; then
    echo "No xrandr command available ... you have to fix it."
    exit 1
fi

XROUT=$(xrandr -q)

# use configuration given as argument
CONFIG=$1
# if specified, otherwise try autodetection
if [[ -z "$CONFIG" ]]; then
    if [[ "$(grep " connected " <<<"$XROUT" | wc -l)" = "1" ]]; then
        CONFIG=default
    elif grep -q "DP2-2 connected" <<<"$XROUT"; then
        CONFIG=work
    elif grep -q "VGA1 connected" <<<"$XROUT"; then
        EXTRA_ID=$(md5sum /sys/class/drm/card0-VGA-1/edid | cut -f1 -d' ')
        echo "EDID: $EXTRA_ID"
        [[ "$EXTRA_ID" = "b3bd2d4d69de88ff12cba4b2d883ec3c" ]] && CONFIG=home
    fi
    # place your autodetection here

    #echo "Autodetected monitor layout: $CONFIG"
fi

#DEFAULT="LVDS-0"
DEFAULT="${DEFAULT:-$(xrandr |sed -rn 's/(.*) connected .*/\1/p'|head -n1)}"

# first everything off to clean possible manual changes,

# also workarounds issue with razor-qt WM, which may calculate positions
# incorrectly after display is switched
# ~ https://github.com/Razor-qt/razor-qt/issues/612

whichstate="(dis)?connected"
$SAFEONLY && whichstate="disconnected"
for DISP in $(sed -nr "s/^(.*) $whichstate.*/\1/p" <<<"$XROUT"); do
    [[ "$DISP" = "$DEFAULT" && $SAFEONLY ]] && continue
    xrandr --output $DISP --off
done

# always switch back to default
xrandr --output $DEFAULT --auto --rotate normal --reflect normal --primary


case $CONFIG in
    home)
        xrandr --output VGA1 --auto --primary --output $DEFAULT --off
        ;;
    rust)
        xrandr --output DVI-I-1 --auto --primary --scale-from 1280x720
        ;;
    work)
        xrandr --output DP2-2 --auto --right-of $DEFAULT --output $DEFAULT --auto --primary
        ;;
    present)
        xrandr --output VGA1 --auto --left-of $DEFAULT --output $DEFAULT --auto --primary
        ;;
    present-mirror)
        xrandr --output VGA1 --same-as $DEFAULT
    #    xrandr --output VGA1 --off --output $DEFAULT --auto --rotate normal --reflect normal --primary
        ;;
    small)
        xrandr --output $DEFAULT --scale 0.67x0.67
        ;;
    default)
        # use just display of nb
        #xrandr --output HDMI3 --off --output $DEFAULT --auto --rotate normal --reflect normal --primary
        # do nothing as we should be in the default now
        ;;
    -h|--help|help|*)
        echo "Usage:"
        echo "$0 [work | default]" # list possible configurations here
        ;;
esac

