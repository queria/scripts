#!/bin/bash

# pipe to this script repo urls, one per line
#
# repodata/repomd.xml paths
#
# $basearch gets replaced by x86_64 (or set $basearch)

basearch="${basearch:-x86_64}"

[[ "$1" = "-v" ]] && set -x

sed "s|\$basearch|${basearch}|" | \
sed -r 's|/?(repodata/repomd.xml)?$|/repodata/repomd.xml|' | \
while read URL; do
    URLINFO=$(curl --fail -s -I "$URL" | sed -nr 's/^(Last-Modified|Date): //p' || echo "FAIL     ")

    echo "**** ${URL}"
    echo "${URLINFO}"
    echo ""
done
