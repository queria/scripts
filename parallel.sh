#!/bin/bash

if [[ "$#" -lt "2" ]]; then
    echo "Usage:"
    echo "  parallel [COUNT] [COMMAND(S) TO EXECUTE]"
    exit 1
fi

### Launches given multiple command multiple times.
### And prints output for each run when it ends.

### Pipes or multicommands in generall are not supported
### (no 'unquoting' done so no way how to pass them through now).
### So currently it's working only for simple commands like:
###   parallel.sh 10 somecommand args args args


COUNT=$1
shift

echo "==== Going spawn $COUNT tasks ... ===="

time (
time for X in $(seq $COUNT); do
    echo "$X - $($@)" &
done;
echo "==== Spawned, waiting for results ... ===="
wait)

echo "==== All tasks finished ===="
