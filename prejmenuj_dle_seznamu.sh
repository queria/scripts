#!/bin/sh
MOVECONFIRMED="false"

# use anything as arg to 'pretend'

# nothing/-h/--help to see this
if [ $# -eq 0 -o "$1" = "-h" -o "$1" = "--help" ];
then
	echo "Edit me ... $0"
	exit 1
fi

# -mv to confirm results are ok and execute mv command
if [ "$1" = "-mv" ];
then
	MOVECONFIRMED="true"
fi



SOURCE_LIST=../seznam

for FILE in *;
do
	MATCHPART=$(echo $FILE | awk '{ print $2 }' | sed "s/\..*$//");
	REPLACEPART=$(grep "${MATCHPART}" "${SOURCE_LIST}")
	if [ "-${MATCHPART}-" = "--" -o "-${REPLACEPART}-" = "--" ];
	then
		echo "Bad file/.../ ${FILE}"
		continue
	fi
	NEWFILE=$( echo ${FILE} | sed "s/${MATCHPART}/${REPLACEPART}/")
	echo "Renaming '${FILE}' to '${NEWFILE}'"
	if [ "${MOVECONFIRMED}" = "true" ];
	then
		mv "${FILE}" "${NEWFILE}"
	fi
done

if [ ${MOVECONFIRMED} = "false" ];
then
	echo
	echo
	echo "This was only preview ... "
	echo " ... check results and use '-mv' as first arg if everething looks ok to you"
fi

