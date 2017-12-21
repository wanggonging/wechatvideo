#!/bin/bash
#youtube-dl -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' -o $1 $2
youtube-dl -f 'bestvideo[width<=740]+bestaudio/best[width<=740]' -o $1 $2
if [ ! "a$3" != "a-t" ]; then
	exit
fi

if [ -f $1.mp4 ]; then
 ./t $1.mp4 -q
else
 ./t $1.mkv -q
fi

