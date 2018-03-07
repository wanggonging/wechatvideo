#!/bin/bash

[[ -z $g_CacheRoot ]] && source globals.sh

g_audio="-b:a 20k -ac 1 -ar 8000"
g_crf=35
g_fps=10
g_LogFile=$g_CacheRoot/encoder.log

[[ -d $g_CacheRoot ]] || mkdir $g_CacheRoot
g_VRoot=$g_CacheRoot/v
[[ -d $g_VRoot ]] || mkdir $g_VRoot

function Log {
	echo `date "+%y%m%d-%H:%M:%S"` $cn $* >> $g_LogFile
}

function EncodeVideo {
	local source_file=$1
	local target_file=$2
	local Title=$3

	local DURATION_HMS=$(ffmpeg -i "$source_file" 2>&1 | grep Duration | cut -f 4 -d ' ')
	local DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
	local DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
	if [ "$DURATION_H" == "00" ] && [ "$DURATION_M" == "00" ]; then
		if [[ `du $source_file|cut -f1`	-ge 4096 ]]; then
		       	rm -f $source_file
			rm -f $target_file
		       	echo Live streaming detected/deleted: $source_file
		       	return 0
		fi
	       	rm -f $source_file
		rm -f $target_file
		echo Ignored. Source file duration too small: $DURATION_HMS
		return 0
	fi

	[[ -f $target_file ]] && ffprobe -loglevel 16 $target_file && continue
	echo Encoding $source_file to $target_file ...
	local Title1=${Title:0:10}
	local Title2=${Title:10:10}
	local Title3=${Title:20:10}
	local Title4=${Title:30:10}
	local Title5=${Title:40:10}
	local Title6=${Title:50:10}
	sed -e "s/AAAAAAA/$Channel${M}${D}\\\\N$Title1 $Title2 $Title3 $Title4 $Title5 $Title6/g" template_v2.asst > template_tmp
	ffmpeg -hide_banner -nostdin -loglevel warning \
		-i $source_file -y \
	     	-strict -2 $g_audio \
	     	-crf $g_crf -r ${g_fps} \
	       	-vf ass=template_tmp \
	    	$target_file

	DURATION_HMS=$(ffmpeg -i "$target_file" 2>&1 | grep Duration | cut -f 4 -d ' ')
	echo Duration: $DURATION_HMS
	DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
	DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
	if [ "$DURATION_H" == "00" ] && [ "$DURATION_M" == "00" ]; then
		Log Live stream detected removing $source_file: [$DURATION_HMS]
		rm -f $source_file
		Log Live stream detected removing $target_file: [$DURATION_HMS]
		rm -f $target_file
	fi
}

function EncodeChannel {
	local cn=$1
	local channel_root=$g_CacheRoot/$cn
	local channel_wget=$g_CacheRoot/wget/channel.wget
	local channel_keys=$channel_root/KEYS
	local channel_json_flat=$channel_root/INDEX.json
	local index
        cat $channel_json_flat | while read index
	do
		local date_published=`echo $index | cut -d\" -f 4`
		local key=`echo $index | cut -d\" -f 8`
		local title=`echo $index | cut -d\" -f 12`
		title=${title#\"}
		title=${title// /　}  # replace space with full space so that $title can be passed as an arg.
		title=${title//\//／}  # replace / with full so that $title can be used in sed.
		local v_file=$g_VRoot/$key.mp4
		local cache_file=$g_CacheRoot/mp4/$key.mp4
		[[ -f $cache_file ]] || continue
		EncodeVideo $cache_file $v_file $title
	done
}

function EncoderLoop {
	while :
	do
		local cn
		for cn in $g_Channels
		do
			EncodeChannel $cn
		done
		echo Sleep 3600 zzz...
		sleep 3600
	done
}

return 0

if [[ ! -z $1 ]]
then
	case $1 in
		"1")
			EncodeChannel MJDD
			;;
		*) echo invalid option;;
	esac
fi
