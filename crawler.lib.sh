#!/bin/bash

[[ -z $g_CacheRoot ]] && source globals.sh

g_LogFile=$g_CacheRoot/crawler.log

[[ -d $g_CacheRoot ]] || mkdir $g_CacheRoot

function Log {
	echo `date "+%y%m%d-%H:%M:%S"` $cn $* >> $g_LogFile
}

function CallWget {
	Log $*
	wget $*
	sleep 2
}

function DownloadYouTube {
	local key=$1
	local cache_file=$2
	r=400
	youtube-dl  -f "(mp4)[height<=$r]" -o $cache_file https://www.youtube.com/watch?v=$key
	echo sleep 2
	sleep 2
}

function DownloadWatchFile {
	local key=$1
	local watch_file=$2
	CallWget -nv https://www.youtube.com/watch?v=$key -O $watch_file
}

function DownloadJsonFile {
	local kye=$1
	local json_file=$2
	CallWget -nv https://www.googleapis.com/youtube/v3/videos?id=$key\&part=snippet,statistics,recordingDetails\&key=$g_GoogleApiKey -O $json_file
	sleep 2
}

function DownloadImage {
	local watch_file=$1
	local image_file=$2
	local image_url=`cat $watch_file | pup meta | grep og:image \
			| pup "meta json{}"\
			| jq '.[]|.content'`
	image_url=${image_url%\"}
	image_url=${image_url#\"}
	CallWget -nv $image_url -O $image_file || rm $image_file
}

function CrawlChannel {
	local cn=$1
	local channel_root=$g_CacheRoot/$cn
	local channel_json_flat=$channel_root/INDEX.json

	local n=0
        cat $channel_json_flat | while read index
	do
		local date_published=`echo $index | cut -d\" -f 4`
		local today=`date +%s`
		local hours_to_go_back=${g_ChannelHoursToGoBack[$cn]}
		if [[ -z $hours_to_go_back ]]; then
			hours_to_go_back=$g_DefaultHoursToGoBack
		fi
		local date_to_compare=`date -d "$date_published +$hours_to_go_back hour" +%s`
		if [[ $today -ge $date_to_compare ]] && [[ $n != 0 ]]; then # too old,skip
			continue
		fi
		n=$(($n+1))
		local key=`echo $index | cut -d\" -f 8`
		local cache_file=$g_CacheRoot/mp4/$key.mp4
		local image_file=$g_CacheRoot/jpg/$key.jpg
		local watch_file=$g_CacheRoot/watch/$key.watch
		local json_file=$g_CacheRoot/json/$key.json
		[[ -d $g_CacheRoot/watch ]] || mkdir $g_CacheRoot/watch
		[[ -d $g_CacheRoot/jpg ]] || mkdir $g_CacheRoot/jpg
		[[ -d $g_CacheRoot/json ]] || mkdir $g_CacheRoot/json
		[[ -d $g_CacheRoot/mp4 ]] || mkdir $g_CacheRoot/mp4
		[[ -f $watch_file ]] || DownloadWatchFile $key $watch_file
		[[ -f $image_file ]] || DownloadImage $watch_file $image_file
		[[ -f $json_file ]] || DownloadJsonFile $key $json_file
		[[ -f $cache_file ]] || \
			for i in `ls ~/OneDrive/cache/$cn/*$key*.mp4 2>/dev/null`
		       	do
				echo cp $i $cache_file
				cp $i $cache_file
			done
		if [[ ! -f $cache_file ]]
		then
			echo $index
			DownloadYouTube $key $cache_file
		fi
	done
}

function CrawlerLoop {
	while :
	do
		local cn
		for cn in $g_Channels
		do
			CrawlChannel $cn
		done
		echo Sleep 3600 zzz...
		sleep 3600
	done
}

function PopulateVirtualChannel {
	local virtual_cn=$1
	local cn=${virtual_cn:0:2}
	[[ "$virtual_cn" == "$cn" ]] && return 0

	local channel_root=$g_CacheRoot/$cn
	local virtual_channel_root=$g_CacheRoot/$virtual_cn
	[[ -d $virtual_channel_root ]] || mkdir $virtual_channel_root
	Selector_$virtual_cn $channel_root/INDEX.json > $virtual_channel_root/INDEX.json
}

function PopulateChannel {
	local cn=$1
	local full=$2
	local channel_root=$g_CacheRoot/$cn
	local channel_json=$channel_root/channel.json
	local channel_json_flat=$channel_root/INDEX.json
	local channel_keys=$channel_root/KEYS
	[[ -d $channel_root ]] || mkdir $channel_root

	local total_count
	local current_count
	local token=
	current_count=0
	rm -f $channel_keys.tmp
	rm -f $channel_json.new
	while :
	do
#		CallWget -nv https://www.googleapis.com/youtube/v3/search?key=AIzaSyA_ltEFFYL4E_rOBYkQtA8aKHnL5QR_uMA\&channelId=${g_ChannelId[$cn]}\&part=snippet,id\&order=date\&maxResults=50\&pageToken=$token -O $channel_json.tmp
		CallWget -nv https://www.googleapis.com/youtube/v3/search?key=$g_GoogleApiKey\&channelId=${g_ChannelId[$cn]}\&part=snippet,id\&order=date\&maxResults=50\&pageToken=$token -O $channel_json.tmp
		sleep $g_GlobalApiSleep
		cat $channel_json.tmp >> $channel_json.new
		total_count=`grep totalResults $channel_json.tmp|cut -d: -f2`
		total_count=${total_count%,}
		echo total_count = $total_count
		token=`grep nextPageToken $channel_json.tmp|cut -d\" -f4`
		echo token $token
		grep videoId $channel_json.tmp | cut -d\" -f4 > $channel_keys.tmp
		cat $channel_keys.tmp >>$channel_keys
		count=`cat $channel_keys.tmp | wc -l`
		let current_count=$current_count+$count
		echo $count, $current_count
		if [[ $count == 0 || -z $token || -z $full ]]; then
			break
		fi
		sleep 2
	done
	sort $channel_keys -u >$channel_keys.tmp
	cp $channel_keys.tmp $channel_keys
	echo Found unique keys: `wc -l $channel_keys`
	cat $channel_json.new | jq -c '.items[]|select(.id.kind=="youtube#video")|{publishedAt:.snippet.publishedAt, id:.id.videoId, title:.snippet.title}' >$channel_json_flat.tmp
	cat $channel_json_flat >>$channel_json_flat.tmp
	cconv -f UTF8 -t UTF8-CN $channel_json_flat.tmp | sort -ru >$channel_json_flat
	echo Channel json items: `wc -l $channel_json_flat`
}

function PopulatorLoop {
	while :
	do
		local cn
		for cn in $g_Channels
		do
			PopulateChannel $cn
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
			echo "You chose 1"
			PopulateChannel MJ
			;;
		"2")
			echo "You chose 2"
			PopulateChannel YP full
			;;
		"3")
			echo "You chose 3"
			PopulateVirtualChannel MJDD
			;;
		"4")
			CrawlChannel MJDD
			;;
		*) echo invalid option;;
	esac
fi
