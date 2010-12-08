#!/bin/sh

if [ "$1" != "go" ];
then
	echo "Pouze ukazuji vysledek nacteni tagu ze souboru."
	echo "Pro skutecne nastaveni pouzij jako argument volani skriptu text \"go\"."
	echo ""
fi

echo "--- ARTIST ^^^ ALBUM ^^^ TRACKNUM ^^^ SONGNAME ^^^ YEAR ^^^ COMMENT ^^^ GENRE ---"

for F in *.mp3;
do
	SONGNAME=$(id3ed -i "$F"|grep "songname:"|sed 's/songname: //')
	ARTIST=$(id3ed -i "$F"|grep "artist:"|sed 's/artist: //')
	ALBUM=$(id3ed -i "$F"|grep "album:"|sed 's/album: //')
	YEAR=$(id3ed -i "$F"|grep "year:"|sed 's/year: //')
	COMMENT=$(id3ed -i "$F"|grep "comment:"|sed 's/comment: //')
	TRACKNUM=$(id3ed -i "$F"|grep "tracknum:"|sed 's/tracknum: //')
	GENRE=$(id3ed -i "$F"|grep "genre:"|sed 's/^.*(\([0-9\]\+\))$/\1/')
	echo "^^^ ${ARTIST} ^^^ ${ALBUM} ^^^ ${TRACKNUM} ^^^ ${SONGNAME} ^^^ ${YEAR} ^^^ ${COMMENT} ^^^ ${GENRE} ^^^"
	if [ "$1" != "go" ];
	then
		continue
	fi
	id3ed -q -s "$SONGNAME" -n "$ARTIST" -a "$ALBUM" -y "$YEAR" -c "$COMMENT" -k "$TRACKNUM" -g "$GENRE" "out/$F"
done

# 01 - More.mp3: (tag v1.1)
# songname: More
# artist: Poets Of The Fall
# album: Revolution Roulette
# year: 2008
# comment: POTF RULES!
# tracknum: 1
# genre: Rock(17)

