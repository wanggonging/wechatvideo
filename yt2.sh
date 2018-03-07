#!/bin/bash

source crawler.lib.sh
source encoder.lib.sh
source metadata.lib.sh
source qrcoder.lib.sh


function BuildRootIndex {
	local ip=$1
	local host_root=$2
	local index_html=$2/$3
	echo Generating $index_html ...
	rm -f $index_html

	echo '<html><head>
		<style type="text/css">
		img { width:auto; max-width:100%; height: auto ; }
		</style>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1" />
		</head><body>' >$index_html
	cat wechat-cover.html >>$index_html
	convert jump.jpg \
		-gravity NorthWest \
	        -font Noto-Sans-CJK-JP-Bold \
		-fill '#E0E0E0' -pointsize 30 -draw "text 15,55 '动动手指，跳出微信枷锁'" \
		-fill '#E0E0E0' -pointsize 20 -draw "text 80,280 '苹果用户：请选择在Safari中打开'" \
		$host_root/jump.jpg

	#
	# First grab the first entry of all channels and sort them
	#
	local cn
	local index
	local key
	local date_published
	local index_tmp=index2_tmp
	local count
	rm -f $index_tmp
	for cn in $g_VirtualChannels
	do
		[[ -f $g_CacheRoot/$cn/INDEX ]] || continue
		index=`head -n 1 $g_CacheRoot/$cn/INDEX`
		[[ -z $index ]] && continue
		date_published=${index%%;*}
		index=${index#*;}
		key=${index%%;*}
		count=`grep mp4 $g_HostRoot/${g_ChannelHost[$cn]}/$cn/index.html | wc -l`
		if [[ "$count" -gt "$g_MaxItemsPerChannel" ]]; then
			count=$g_MaxItemsPerChannel
		fi
		echo $date_published\;$cn\;$key\;$count>>$index_tmp
	done
	sort -r $index_tmp | while read index
	do
		date_published=${index%%;*}
		index=${index#*;}
		cn=${index%%;*}
		index=${index#*;}
		key=${index%%;*}
		index=${index#*;}
		count=${index%%;*}
		local table='<table width="100%"><tr><td></td><td align="right"><a href="http://'${g_ChannelHost[$cn]}/$cn'">更多(共'$count'个视频)</a></td></tr></table>'
		local img='<a href="http://'${g_ChannelHost[$cn]}/v/$key.mp4'"><img src="http://'${g_ChannelHost[$cn]}/q/$key.jpg'" /></a><br><p><hr>'
		echo $table$img>>$index_html
	done
	echo '<i>服务器地址: <a href="http://45.77.144.52">45.77.144.52</a></i> | <a href="v1.html">旧版主页</a>'>>$index_html
	echo '</body></html>'>>$index_html
}

function Sync {
	BuildRootIndex $g_MainHost $g_MainHostRoot index.html
	rsync -av $g_HostRoot/$g_Host1/ root@$g_Host1:/var/www/html
	rsync -av $g_HostRoot/$g_MainHost/v root@$g_MainHost:/var/www/html
	rsync -av $g_HostRoot/$g_MainHost/q root@$g_MainHost:/var/www/html
	rsync -av $g_HostRoot/$g_MainHost/ root@$g_MainHost:/var/www/html
}

function OneChannel {
	local cn=$1
	local old_count=`cat $g_CacheRoot/$cn/INDEX|wc -l`
	echo PopulateVirtualChannel ...
	PopulateVirtualChannel $cn
	echo CrawlChannel $cn ...
	CrawlChannel $cn
	echo EncodeChannel $cn ...
	EncodeChannel $cn
	echo ExtractChannelMetaData $cn ...
	ExtractChannelMetaData $cn
	echo Building QR+Index for $cn ...
	BuildChannel $cn
	local new_count=`cat $g_CacheRoot/$cn/INDEX|wc -l`
	echo $old_count vs $new_count
	if [[ $old_count != $new_count ]]
	then
		Sync
	fi
}

function Main {
	if [[ ! -z $1 ]]; then
		g_DefaultHoursToGoBack=$1
	fi
	echo Using DefaultHoursToGoBack=$g_DefaultHoursToGoBack ...
	sleep 2
	while :
	do
		local cn
		local vcn
		for cn in $g_ChannelsSimple
		do
			PopulateChannel $cn
			OneChannel $cn
		done
		for cn in $g_ChannelsComplex
		do
			PopulateChannel $cn
			for vcn in $g_VirtualChannelsOnly
			do
				if [[ ${vcn:0:2} == $cn ]]; then
					OneChannel $vcn
				fi
			done

		done
		Sync
		#g_DefaultHoursToGoBack=$((g_DefaultHoursToGoBack+24))
		echo Sleep 60 zzz, next default hours to go back: $g_DefaultHoursToGoBack ...
		sleep 60
	done
}

function Usage {
	echo Usage:
	echo    $0 boot
       	echo 	$0 all, sync, buildroot
	echo 	$0 one,v \<channel\>
}

function Boot {

	#
	# All ubuntu packages required by ytdaily
	#
	sudo apt install -y ffmpeg cconv qrencode imagemagick jq goaccess
}

if [[ ! -z $1 ]]
then
	case $1 in
		"boot")
			Boot
			;;

		"buildroot")
			BuildRootIndex $g_MainHost $g_MainHostRoot index.html
			;;
		"all")
			Main $2
			;;
		"sync")
			Sync
			;;
		"one")
			g_GlobalApiSleep=0
			vcn=$2
			cn=${vcn:0:2}
			PopulateChannel $cn
			OneChannel $vcn
			Sync
			;;
		"v")
			g_GlobalApiSleep=0
			OneChannel $2
			Sync
			;;
		*)
			echo invalid option
			Usage
			;;
	esac
else
	Usage
fi
