#!/bin/bash

if [ -z "$1" ];
then
	echo "Please enter number of commits (back in history) ..."
	echo "... from which ones i will list changed files."
	echo ""
	echo "you can test this number using: git log -NUMBER"
	exit 1
fi

git log --name-status -"${1}" | grep "^[AM]\W" | awk '{ print $2 }' | sort -u
git log --name-status -"${1}" | grep "^[D]\W" | awk '{ print "--"$2 }' | sort -u

