#!/bin/bash

usage() {
    echo ""
    echo "Usage:"
    echo ""
    echo "mv2pattern pattern-id source-file-path/name ident-in-series[=auto]"
    echo ""
    echo "Example:"
    echo "  With pattern (in ~/mv-patterns file) defined like:"
    echo "  > cirros_PREFIX=\"/tmp/cirros-\""
    echo "  > cirros_SUFFIX=\"tar.gz\""
    echo "  Following command:"
    echo "  $ mv2pattern.sh cirros ~/Downloads/cirros-x86_64_big_version_whatever_3.11.1.0.4.uec.tar.gz 3.11.1"
    echo "                  |p-id| |......    source-file-path .......................................| |s-id|"
    echo ""
    echo "  Would move the specified file (~/Downloads/...)"
    echo "  to /tmp/cirros-3.11.tar.gz"
    echo ""
    echo "In the mv-patterns you can use \"%suff\" in the suffix part"
    echo "Which will be replaced with original suffix (after last dot) of file"
    echo ""
    echo "As *ident-in-series* you can use 'auto' (default when ident is not specified)"
    echo "which will try to auto-detect the serie and episode number"
    echo "from source-file-name as S0E0 or 0x0? (case-insensitive, 0=0-9+)."
    echo ""
}

if [[ -z "$1" || -z "$2" || "$1" == "--help" ]]; then
    # improper amount of args or help requested
    usage
    exit 0
fi

if [[ ! -f ~/mv-patterns ]]; then
    echo "Create ~/mv-patterns like..."
    echo ""
    echo "PATT_PREFIX"
    echo "PATT_SUFFIX"
    usage
    exit 1
fi

if [[ ! -f "$2" ]]; then
    echo "ERROR: File '$1' NOT FOUND"
    usage
    exit 2
fi


. ~/mv-patterns

set -e

SRC="$2"
ORIG_SUFF=".${SRC##*.}"
PREFIX="$(eval echo "\${${1}_PREFIX}")"
SUFFIX="$(eval echo "\${${1}_SUFFIX}")"
SUFFIX="${SUFFIX/\%suff/${ORIG_SUFF}}"
SEQ_IDENT="${3:-auto}"

if [[ "$SEQ_IDENT" == "auto" ]]; then
    SEQ_IDENT=$(basename "$SRC" | perl -ne '/(s)?(\d+)(?(1)e|x)(\d+)/i && printf("S%02dE%02d", $2, $3);')
fi

TARGET="${PREFIX}${SEQ_IDENT:?"Sequence identifier is empty, auto-detection failed?!"}${SUFFIX}"

mv -v -i "${SRC}" "${TARGET}"

