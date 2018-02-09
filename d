#!/bin/bash
#youtube-dl -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' -o $1 $2
r=400
if [ "$res" != "" ]
then
	r=$res
fi
echo $d

special=0
if [[ $2 = *guo.media* ]]; then
	echo Guo Media detected ....
	youtube-dl  -o cache/$1.mp4 $2
	special=1
fi
if [[ $2 = *ntdtv* ]]; then
	echo NTDTV detected ....
	youtube-dl  -o cache/$1.mp4 $2
	special=1
fi

if [ "$special" == "0" ]; then
	if [ "$d" != "0" ]; then
		#	youtube-dl --no-part -f 'bestvideo[width<=740]+bestaudio/best[width<=740]' -o $1 $2
		youtube-dl  -f "(mp4)[height<=$r]" -o cache/$1.mp4 $2
	fi
fi

quiet="-q"
prefix=""
if [ "$debug" == "1" ]; then
	quiet=""
	prefix="bash -x"
fi

if [ -f cache/$1.mp4 ]; then
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

echo Wrong!
