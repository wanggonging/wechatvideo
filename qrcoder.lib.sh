#!/bin/bash

[[ -z $g_CacheRoot ]] && source globals.sh

g_LogFile=$g_CacheRoot/qrcoder.log

function Log {
	echo `date "+%y%m%d-%H:%M:%S"` $cn $* >> $g_LogFile
}

function GenQrcode {
	local cn=$1
	local key=$2
	local qrfile=$3
	local targeturl=$4
	local imagefile=$5
	local date_published=$6
	local duration=$7
	local filesize=$8
	local title=$9
	local ipstring=${10}
	local qrbgcolor=${11}

	local qr_tmp=$qrfile.qr.jpg
 	qrencode -m 1 -s 12 -o $qr_tmp $targeturl
	local Title1=${title:0:20}
	local Title2=${title:20:20}
	local Title3=${title:40:20}
	local Title4=${title:60:20}
	local d1=`date -d $date_published "+%Y年%m月%d日%H点%M分"`
	local d2=`date -d $date_published "+%m%d"`
	convert -size 400x500 xc:$qrbgcolor \
		-gravity SouthEast finger.jpeg[90x90] -geometry +100+30 -compose Over -composite \
		-gravity Center \( $imagefile -resize 400x225^ -extent 400x225 \) -geometry +0+20 -compose Over -composite \
		-gravity SouthEast $qr_tmp[100x100] -geometry +0+15 -compose Over -composite \
		-gravity NorthEast \
	        -font Noto-Sans-CJK-JP-Bold \
		-fill blue -pointsize 30 -draw "text 30,0 '每'" \
		-fill red -pointsize 30 -draw "text 2,0 '日'" \
		-fill green -pointsize 30 -draw "text 30,30 '油'" \
		-fill black -pointsize 30 -draw "text 2,30 '兔'" \
		-fill black -pointsize 10 -draw "text 0,143 '$ipstring'" \
		-gravity NorthWest \
		-fill '#333333' -pointsize 26 -draw "text 10,2 '${g_ChannelName[$cn]}$d2'" \
		-font Noto-Sans-CJK-JP-Thin \
        	-font Noto-Sans-CJK-JP-Regular \
		-fill black -pointsize 12 -draw "text 10,39 '$d1'" \
		-fill black -pointsize 12 -draw "text 10,59 '时长: $duration   流量: $filesize'" \
        	-font Noto-Sans-CJK-JP-Regular \
		-fill black -pointsize 16 -draw "text 10,79 '$Title1'" \
		-fill black -pointsize 16 -draw "text 10,99 '$Title2'" \
		-fill black -pointsize 16 -draw "text 10,119 '$Title3'" \
		-fill black -pointsize 16 -draw "text 10,139 '$Title4'" \
		-gravity SouthWest \
		-fill red -pointsize 19 -draw "text 10,88 '微信观看视频方法:'" \
		-fill red -pointsize 16 -draw "text 20,65 '1. 长按指纹识别二维码" \
		-fill red -pointsize 16 -draw "text 20,40 '2. 点击\"继续访问\"'" \
		-fill blue -pointsize 11 -draw "text 5,17 '联系每日油兔: WhatsApp/SOMA: +1 253 753 9981'" \
		-fill blue -pointsize 10 -draw "text 5,2 '推特/电报: @wanggonging 电邮: wanggonging@gmail.com'" \
		-gravity SouthEast \
		-fill '#00000080' -stroke '#00000080' -draw "rectangle 343,363 395,377" \
		-gravity NorthWest \
		-font Noto-Sans-CJK-KR-Thin \
		-fill white -stroke white -pointsize 11 -draw "text 350,361 '$duration'" \
		-fill '#00000080' -stroke white -draw "circle 200,270 200,310" \
		-fill white -stroke white -draw "polygon 220,270 190,287 190,253" \
		-quality 30  \
		$qrfile
	echo Generated $qrfile
	rm $qr_tmp
}

function BuildChannel {
	local virtual_cn=$1
	local virtual_channel_root=$g_CacheRoot/$virtual_cn
	local v_root=$g_CacheRoot/v
	local virtual_channel_index=$virtual_channel_root/INDEX
	local host=${g_ChannelHost[$virtual_cn]}
	local host_root=$g_HostRoot/$host
	local index_host_root=$g_HostRoot/${g_ChannelHost[$virtual_cn]}
	local host_q_root=$host_root/q
	local host_v_root=$host_root/v
	local host_channel_root=$index_host_root/$virtual_cn
	local index_html=$host_channel_root/index.html
	[[ -d $host_root ]] || mkdir $host_root
	[[ -d $index_host_root ]] || mkdir $index_host_root
	[[ -d $host_q_root ]] || mkdir $host_q_root
	[[ -d $host_v_root ]] || mkdir $host_v_root
	[[ -d $host_channel_root ]] || mkdir $host_channel_root

	echo Building $index_html ...
	rm -f $index_html
	echo '<html><head>
		<style type="text/css">
		img { width:auto; max-width:100%; height: auto ; }
		</style>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1" />
		</head><body>' >$index_html
	cat wechat-cover.html >>$index_html
	local total=0
	local index
	cat $virtual_channel_index | while read index
	do
		local date_published=${index%%;*}
		index=${index#*;}
		local key=${index%%;*}
		index=${index#*;}
		local duration=${index%%;*}
		index=${index#*;}
		local qrfile=$host_q_root/$key.jpg
		local targeturl=http://$host/v/$key.mp4
		local imagefile=$g_CacheRoot/jpg/$key.jpg
		local v_file=$v_root/$key.mp4
 		local filesize=`du -h $v_file|cut -f1`
		local title=${index%\"}
		title=${title#\"}
		title=${title// /　}  # replace space with full space so that $title can be passed as an arg.
		local ipstring=\[${host%%.*}.$key\]
		local qrbgcolor=white

		[[ -f $qrfile ]] || \
		       	GenQrcode $virtual_cn $key $qrfile $targeturl $imagefile \
				$date_published $duration $filesize $title $ipstring $qrbgcolor
		local host_v_file=$host_v_root/$key.mp4
		[[ -f $host_v_file ]] || cp $v_file $host_v_file
		grep $key $index_html && continue  # avoid live stream duplicates
		if [ $total -lt $g_MaxItemsPerChannel ]
		then
			echo '<a href="'http://$host/v/$key.mp4'"><img src="'http://$host/q/$key.jpg'" /></a><hr>'>>$index_html
			total=$(($total+1))
		fi
	done
	echo '</body></html>'>>$index_html
}

function BuildChannelLoop {
	while :
	do
		local cn
		for cn in $g_VirtualChannels
		do
			BuildChannel $cn
		done
		echo Sleep 3600 zzz...
		sleep 3600
	done
}

return 0

if [[ "$1" ]]; then
	BuildChannel $1
	cat $g_HostRoot/$g_MainHost/$1/index.html
fi
