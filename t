#!/bin/bash
filename=$1
if [ -f cache/$1 ]
then
	echo "File name is $filename."
else
	echo "File $filename does not exist!"
	exit 1
fi
input=cache/$filename
filename_withoutext=${filename%.*}

datefull=`TZ="UTC-8" date "+%y%m%d%H%M%S"`
DURATION_HMS=$(ffmpeg -i "$input" 2>&1 | grep Duration | cut -f 4 -d ' ')
DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
DURATION_S=$(echo "$DURATION_HMS" | cut -d ':' -f 3 | cut -d '.' -f 1)
DURATION=`echo "(( $DURATION_H * 60 + $DURATION_M ) * 60 + $DURATION_S) / $speed" | bc -l`
D=`printf %.0f $DURATION`
LENGTH=`echo "($DURATION + $n - 1)/$n" | bc -l`
len=`printf %.0f $LENGTH`
VRATE=`echo "20*1024*8 / $len - 30" | bc -l`
v=`printf %.0f $VRATE`
if [ $v -gt 300 ]
then
	v=300
fi
if [ "$vv" != "" ]
then
	v=$vv
fi

##
# v rate is deprecated, use crf
#
crf=40
if [ "$c" != "" ]
then
	crf=$c
fi

#audio="-q:a 1.5 -ac 1 -ar 8000"
audio="-b:a 20k -ac 1 -ar 8000"
if [ "$aa" != "" ]
then
	audio=$aa
fi

if [ "$volume" = "" ]; then
	volume=1
fi

#tech="ffmpeg 加速${speed} 音40k 视${v}k ${fps}fps $datefull"
tech="$datefull"

if [ -f sub/${filename_withoutext}.ass ]
then
	new=${filename_withoutext}_sub.mkv
	ffmpeg -y -i $input -crf $crf -r $fps -vf ass=sub/${filename_withoutext}.ass -acodec copy $new
	input=$new
fi

if [ "$ss" != "0" ]
then
	new=${filename_withoutext}_ss.mkv
	ffmpeg -y -i $input -crf $crf -r $fps  -acodec copy -ss $ss $new
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
      	-strict -2 $audio \
       	-crf $crf -r $fps \
       	-filter_complex "[0:v]setpts=PTS/${speed}[v];[0:a]volume=$volume[af];[af]atempo=${speed}[a]" \
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
	       	-crf $crf -r ${fps} \
	    	/home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}_${i}_of_${n}.mp4

		rm -f ${filename_withoutext}_${j}.mp4
	done
else
	sed -e "s/AAAAAAA/$S1/g; s/CCCCCCC/$tech/g" template.ass > $filename_withoutext.ass
	ffmpeg \
	-i $input -y \
      	-strict -2 $audio \
     	-crf $crf -r ${fps} \
       	-filter_complex "[0:v]setpts=PTS/${speed}[v1];[v1]ass=$filename_withoutext.ass[v];[0:a]volume=$volume[af];[af]atempo=${speed}[a]" \
       	-map "[v]" -map "[a]" \
    	/home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}.mp4
fi

if [ "a$2" == "a-q" ]; then
	rm -f $filename_withoutext.ass
	rm -f ${filename_withoutext}_ss.*
fi
