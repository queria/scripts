#!/bin/bash

ERR_NOCPU=128
ERR_BADGOV=129

GOV="NONE"
case "$1" in
    "max")
        GOV="performance"
        ;;
    "optim")
        GOV="ondemand"
        ;;
    "min")
        GOV="powersave"
        ;;
esac


CPUS=$(ls -1 -d /sys/devices/system/cpu/cpu*/cpufreq)
if [[ -z "$CPUS" ]]; then
    echo "No CPUs with cpufreq found."
    exit $ERR_NOCPU
fi


if [[ "$GOV" == "NONE" ]]; then
    echo "Specify required cpu performance:"
    echo "$0 [max|optim|min]"
    echo ""

    echo "Current values:"
    for CPU in $CPUS; do
        GOV_FILE="${CPU}/scaling_governor"
        echo "$CPU: $(cat "$GOV_FILE")"
    done
    for CPU in $CPUS; do
        echo "Available choices:"
        cat "${CPU}/scaling_available_governors" | \
            sed -r 's/(powersave)/\1(min)/; s/(ondemand)/\1(optim)/; s/(performance)/\1(max)/';
        break
    done
    exit 0
fi



for CPU in $CPUS; do
    if ! egrep -q "(^|\W)${GOV}(\W|$)" "${CPU}/scaling_available_governors";
    then
        echo "Governor ${GOV} is not supported by ${CPU}!"
        exit $ERR_BADGOV
    fi
done

echo "Going to use ${GOV} governor..."

for CPU in $CPUS; do
    GOV_FILE="${CPU}/scaling_governor"
    PREV=$(cat "$GOV_FILE")
    echo "${GOV}" > "$GOV_FILE"
    echo -n "${CPU}: ${PREV} => "
    cat "$GOV_FILE"
done

