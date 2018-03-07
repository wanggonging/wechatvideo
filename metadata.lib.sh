#!/bin/bash

[[ -z $g_CacheRoot ]] && source globals.sh

g_LogFile=$g_CacheRoot/metadata.log

function Log {
	echo `date "+%y%m%d-%H:%M:%S"` $cn $* >> $g_LogFile
}

function ExtractChannelMetaData {
	local cn=$1
	local channel_root=$g_CacheRoot/$cn
	local channel_index=$channel_root/INDEX
	local channel_json_flat=$channel_root/INDEX.json

	[[ -f $channel_index ]] && rm $channel_index
	[[ -f $channel_index.tmp ]] && rm $channel_index.tmp

	local index
        cat $channel_json_flat | while read index
	do
		local date_published=`echo $index | cut -d\" -f 4`
		local key=`echo $index | cut -d\" -f 8`
		local title=`echo $index | cut -d\" -f 12`
		local v_file=$g_CacheRoot/v/${key}.mp4
		[[ -f $v_file ]] || {
			continue
		}
 		local duration=$(ffmpeg -i "$v_file" 2>&1 | grep Duration | cut -f 4 -d ' ')
		duration=${duration%.*}
		echo $date_published\;$key\;$duration\;$title >>$channel_index.tmp
	done
	sort -ru $channel_index.tmp > $channel_index
	rm $channel_index.tmp
	#cat $channel_index
}

function MetaLoop {
	while :
	do
		local cn
		for cn in $g_Channels
		do
			ExtractChannelMetaData $cn
		done
		echo Sleep 3600 zzz...
		sleep 3600
	done
}

return 0

if [[ "$1" ]]; then
	ExtractChannelMetaData $1
	cat $g_CacheRoot/$1/INDEX
fi
