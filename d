#!/bin/bash
#youtube-dl -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' -o $1 $2
youtube-dl -f 'bestvideo[width<=740]+bestaudio/best[width<=740]' -o $1 $2
if [ ! "a$3" != "a-t" ]; then
	exit
fi

quiet="-q"
prefix=""
if [ $debug == "1" ]; then
	quiet=""
	prefix="bash -x"
fi

if [ -f $1.mp4 ]; then
 $prefix ./t $1.mp4 $quiet
 exit
fi

if [ -f $1.mkv ]; then
 $prefix ./t $1.mkv $quiet
 exit
fi

if [ -f $1.webm ]; then
 $prefix ./t $1.webm $quiet
 exit
fi

