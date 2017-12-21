#!/bin/bash
filename=$1
if [ -f $1 ]
then
	echo "File name is $filename."
else
	echo "File $filename does not exist!"
	exit 1
fi
input=$filename
filename_withoutext=${filename%.*}

#n=1&&ss=0&&S1="文在寅访华丧权辱国 受尽屈辱 因传播郭文贵爆料 被捕判刑者激增 《今日热评》12.20"
#n=3&&ss=25&&S1="又是減稅又是 廢除網絡中立 川普到底靠不靠譜？ 《明鏡專訪》12.20"
#n=2&&ss=0&&S1="陳破空文昭对谈 拆毛邓题词不拆江题词 习近平有何盘算 新唐人电视 2017.12.19"
#n=3&&ss=8&&S1="著名人權律師劉士輝 為計生受害者打官司 《計劃生育回頭看》第6期 2017.12.20"
#n=1&&ss=0&&S1="【环球直击】 12月20日完整版 新唐人电视 2017.12.20"
#n=1&&ss=0&&S1="黄琦病危 下月移送法院审讯 新唐人电视 2017.12.20"
#n=1&&ss=0&&S1="沧县天然气爆炸伤人 民众市府抗议 新唐人电视 2017.12.20"
#n=1 && ss=0 && S1="這三個月不會打朝鮮 《點點今天事》 2017年12月20日"
#n=4 && ss=41 && S1="蝴蝶三人行 盲流子曝张欣平语音 揭露其欺骗网友行径 2017.12.19"

datefull=`TZ="UTC-8" date "+%y%m%d%H%M%S"`
DURATION_HMS=$(ffmpeg -i "$input" 2>&1 | grep Duration | cut -f 4 -d ' ')
DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
DURATION_S=$(echo "$DURATION_HMS" | cut -d ':' -f 3 | cut -d '.' -f 1)
DURATION=`echo "(( $DURATION_H * 60 + $DURATION_M ) * 60 + $DURATION_S) / $speed" | bc -l`
D=`printf %.0f $DURATION`
LENGTH=`echo "($DURATION + $n - 1)/$n" | bc -l`
len=`printf %.0f $LENGTH`
VRATE=`echo "20*1024*8 / $len - 50" | bc -l`
v=`printf %.0f $VRATE`
if [ $v -gt 300 ]
then
	v=300
fi

tech="ffmpeg 加速${speed} 音40k 视${v}k ${fps}fps $datefull"

if [ $ss != 0 ]
then
	new=${filename_withoutext}_ss.mkv
	ffmpeg -y -i $input -vcodec copy -acodec copy -ss $ss $new
	input=$new
fi

echo "SS=$ss $D / $n = $len | $S1 | $tech"
if [ ! "a$2" == "a-q" ]
then
	read -n1 -r -p "Press any key to continue..." key
fi


if [ $n -gt 1 ]
then

	ffmpeg \
	-i $input -y \
      	-strict -2 -q:a 1.5 -ac 1 -ar 8000 \
       	-b:v ${v}k -r 25 \
       	-filter_complex "[0:v]setpts=PTS/${speed}[v];[0:a]highpass=f=200,lowpass=f=3000[af];[af]atempo=${speed}[a]" \
       	-map "[v]" -map "[a]" \
	-f segment -segment_time $len -reset_timestamps 1 \
       	${filename_withoutext}_%d.mp4

	for i in `seq 1 ${n}`;
	do
		let j=${i}-1
		if [ ! -f ${filename_withoutext}_${j}.mp4 ]; then
			break
		fi

		sed -e "s/AAAAAAA/$S1\\\\N$i\/$n/g; s/CCCCCCC/$tech/g" template.ass > $filename_withoutext.ass
		ffmpeg -y \
		-i ${filename_withoutext}_${j}.mp4 \
		-vf ass=$filename_withoutext.ass \
		-acodec copy \
	       	-b:v ${v}k -r ${fps} \
	    	/home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}_${i}_of_${n}.mp4

#		rm -f ${filename_withoutext}_${j}.mp4
	done
else
	sed -e "s/AAAAAAA/$S1/g; s/CCCCCCC/$tech/g" template.ass > $filename_withoutext.ass
	ffmpeg \
	-i $input -y \
      	-strict -2 -q:a 1.5 -ac 1 -ar 8000 \
       	-b:v ${v}k -r 25 \
       	-filter_complex "[0:v]setpts=PTS/${speed}[v1];[v1]ass=$filename_withoutext.ass[v];[0:a]highpass=f=200,lowpass=f=3000[af];[af]atempo=${speed}[a]" \
       	-map "[v]" -map "[a]" \
    	/home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}.mp4


#	${filename_withoutext}_speed$speed.mp4

#	ffmpeg -y \
#	-i ${filename_withoutext}_speed$speed.mp4 \
#	-vf ass=$filename_withoutext.ass \
#	-acodec copy \
#       	-b:v ${v}k -r ${fps} \
fi
