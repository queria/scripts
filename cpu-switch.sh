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


if [[ "$GOV" == "NONE" ]]; then
    cat <<HELP
Specify required cpu performance:
$0 [max|optim|min]
HELP
exit 0
fi

CPUS=$(ls -1 -d /sys/devices/system/cpu/cpu*/cpufreq)

if [[ -z "$CPUS" ]]; then
    echo "No CPUs with cpufreq found."
    exit $ERR_NOCPU
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

