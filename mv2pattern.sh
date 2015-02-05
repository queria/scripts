#!/bin/bash
EXIT_HELP=0
EXIT_NOCFG=11
EXIT_NOFILES=21
EXIT_NOPATT=31

CFGF=~/mv-patterns

usage() {
    echo ""
    echo "Usage:"
    echo ""
    echo "mv2pattern (--help | --list | [--pretend] [--inplace] pattern-id source-file-path/name[,...])"
    echo ""
    echo "Example:"
    echo "  With pattern (in ${CFGF} file) defined like:"
    echo "  > cirros_PREFIX=\"/tmp/cirros-\""
    echo "  > cirros_SUFFIX=\"tar.gz\""
    echo "  Following command:"
    echo "  $ mv2pattern.sh cirros ~/Downloads/cirros-x86_64_big_version_whatever_3.11.1.0.4.uec.tar.gz 3.11.1"
    echo "                  |p-id| |......    source-file-path .......................................| |s-id|"
    echo ""
    echo "  Would move the specified file (~/Downloads/...)"
    echo "  to /tmp/cirros-3.11.tar.gz"
    echo ""
    echo "--list ... print known Pattern-IDs"
    echo "--pretend ... only print what would be done, don't realy move files"
    echo "--inplace ... apply pattern for renaming, but use only basename from _PREFIX (ignore path)"
    echo "--flat ... use flat numbering - when there is just one number expected in file name"
    echo ""
    echo "In the mv-patterns you can use \"%suff\" in the suffix part."
    echo "Which will be replaced with original suffix (after last dot) of file."
    echo "And \"%suff\" is also default value of _SUFFIX."
    echo ""
    exit $1
}

[[ "x$1" = "x--help" ]] && usage $EXIT_HELP
[[ ! -f "$CFGF" ]] && usage $EXIT_NOCFG

PRETEND="no"
INPLACE="no"
FLATNUM="no"
OPTS=()
for OPT in "$@"; do
    if [[ "x$OPT" = "x--list" ]]; then
        sed -nr 's/(.*)_(PREFIX|SUFFIX)=.*/\1/p' "$CFGF" | sort -u
        exit $?
    elif [[ "x$OPT" = "x--pretend" ]]; then
        PRETEND="yes"
        echo "[ pretend mode on ]"
    elif [[ "x$OPT" = "x--inplace" ]]; then
        INPLACE="yes"
        echo "[ renaming in place ]"
    elif [[ "x$OPT" = "x--flat" ]]; then
        FLATNUM="yes"
        echo "[ using flat (no series) numbering  ]"
    else
        OPTS=("${OPTS[@]}" "$OPT")
    fi
done


PATT_ID="${OPTS[0]}"
OPTS=("${OPTS[@]:1}")

source "$CFGF"
PREFIX="$(eval echo "\${${PATT_ID}_PREFIX}")"
SUFFIX="$(eval echo "\${${PATT_ID}_SUFFIX}")"
FLATNUM_CFG="$(eval echo "\${${PATT_ID}_FLATNUM}")"
[[ -z "$SUFFIX" ]] && SUFFIX="%suff"
shift

if [[ -z "$PREFIX" ]]; then
    echo "Prefix empty - probably wrong pattern-id?"
    exit $EXIT_NOPATT
fi

if [[ "$INPLACE" = "yes" ]]; then
    PREFIX="$(basename "$PREFIX")"
fi


[[ "$FLATNUM_CFG" = "yes" ]] && FLATNUM="yes"

if [[ $# = 0 ]]; then
    echo "No file specified!"
    exit $EXIT_NOFILES
fi

for FILE in "${OPTS[@]}"; do
    if [[ ! -f "$FILE" ]]; then
        echo "ERROR: File '$FILE' NOT FOUND"
        continue
    fi
    orig_suff=".${FILE##*.}"
    suff="${SUFFIX/\%suff/${orig_suff}}"

    seq_ident=$(basename "$FILE" | perl -ne '/(s)?(\d+)(?(1)(?(1)[- ]*e)|x)(\d+)/i && printf("S%02dE%02d", $2, $3);')
    if [[ "$FLATNUM" = "yes" ]]; then
        seq_ident=$(basename "$FILE" | perl -ne '/(\d+)[._ -]*(.*)\.[^.]+$/i && printf("%02d-%s", $1, $2);')
    fi

    TARGET="${PREFIX}${seq_ident:?"Sequence identifier is empty, auto-detection failed?!"}${suff}"

    if [[ "$PRETEND" = "yes" ]]; then
        echo -e "\"\033[00;32m${TARGET}\033[00m\" <== \"${FILE}\""
    else
        mv -v -i "${FILE}" "${TARGET}"
    fi
done
