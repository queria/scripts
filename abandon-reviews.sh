#!/bin/bash
LST=$(mktemp --suffix _changes)
trap "rm $LST" EXIT

SRV="${1/:*}"
PORT="${1/*:}"
PROJ="$2"
ACTION="${3:-"--abandon"}"
BATCHSIZE=10

if [[ "$1" = "--help" || "$1" = "help" || -z "$PROJ" || -z "$SRV" || -z "$PORT" ]]; then
    echo "Usage:"
    echo " $0 <server> <project> [action=--abandon]"
    echo ""
    echo "Project is the name of project on gerrit like: openstack/tempest"
    echo ""
    echo "Server is in the ssh:// form including port as: [user@]review.example.org:port"
    echo ""
    echo "Action will be passed to *ssh ... gerrit review* command, defaults to '--abandon'."
    echo "You can check available options via it's help like:"
    echo "  ssh -pport review.example.org gerrit review --help"
fi

ssh -p$PORT $SRV gerrit query "status:open project:$PROJ" | sed -nr 's/^  url: .*\/([0-9]+)$/\1/p' > $LST

CNTTOTAL=$(cat $LST|wc -l)
CNT=0
CHANGELIST=""

echo "Working ..."
while read chnum; do
    CNT=$(( $CNT + 1 ))
    CHANGELIST="$CHANGELIST $chnum,1"
    echo -n "$CNT / $CNTTOTAL  [$CHANGELIST]"
    if [[ $(( $CNT % $BATCHSIZE )) = 0 || $CNT = $CNTTOTAL ]]; then
        echo -n " <ssh gerrit>"
        cat /dev/null | ssh -p$PORT $SRV gerrit review $ACTION $CHANGELIST
        CHANGELIST=""
    fi
    echo ""
done < <(cat $LST)
