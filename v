#!/bin/bash
filename=$1
if [ -f $1 ]
then
	echo "File name is $filename."
else
	echo "File $filename does not exist!"
	exit 1
fi
SS2=" "
input=$filename
filename_withoutext=${filename%.*}
len=900 && a=40k && v=130k && fps=25  # 15min
#len=800 && a=40k && v=145k && fps=25  # 15min
#len=715 && a=40k && v=170k && fps=25  # 15min
#len=600 && a=40k && v=200k && fps=25  # 15min
#len=940 && a=40k && v=120k && fps=25  # 20MB
#len=1030 && a=40k && v=100k && fps=25  # 20MB
#len=1000 && a=40k && v=100k && fps=25  # 20MB
#len=1300 && a=40k && v=60k && fps=25  # 20MB
#len=1180 && a=30k && v=100k && fps=25  # 20MB
#len=480 && a=44k && v=300k && fps=25  # 20MB

audio="-b:a $a -strict 2"
audio="-af highpass=f=200,lowpass=f=3000 -strict -2 -q:a 0.3 -ac 1"

#sub="-vf ass=$filename_withoutext.ass"
#sub="-vf ass=tam.ass"
speed=1.3
volume=0
delay=0
ss=0
S3="2017.12.20"
S1="美国之音 时事大家谈" && ss="26 -t 100"
S2="完整版 (2017年12月20日)"
#S1="姜维平读报点评"
#S1="文昭谈古论今 第274期"
#S1="建民论推墙112"
#S1="建平建言"
#S1="点点今天事"
#S1="郭寶勝政論"
#S1="明鏡火拍《友漁讀書》第13期"
#S1="明鏡火拍《紐約看天下》"
#S1="博讯直击"
#S1="縱論天下陳破空"
#S1="蔣罔正（尹科）"
#S1="推视直播台"
#S1="小哥谈政事"
#S1="明鏡火拍《明鏡編輯部》176期"
#S1="中国人权观察"
#S1="大师兄"

date=`TZ="UTC-8" date "+%y%m%d%H%M"`
datefull=`TZ="UTC-8" date "+%y%m%d%H%M%S"`
DURATION_HMS=$(ffmpeg -i "$input" 2>&1 | grep Duration | cut -f 4 -d ' ')
DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
DURATION_S=$(echo "$DURATION_HMS" | cut -d ':' -f 3 | cut -d '.' -f 1)
DURATION=`echo "(( $DURATION_H * 60 + $DURATION_M ) * 60 + $DURATION_S) / $speed" | bc -l`
D=`printf %.0f $DURATION`
let "n= (($D - 1) / $len) + 1"
echo "$D / $len = $n | $S1 | $S2 | $S22 | $S3"
if [ ! "a$2" == "a-q" ]
then
	read -n1 -r -p "Press any key to continue..." key
fi

box="box=1:boxcolor=black@0.6:boxborderw=1"
line1="drawtext=text='$S1':$box:fontcolor=white:fontsize=45:enable='between(t,0,2):y=40:x=(w-tw)/2'"
line2="drawtext=text='$S2':$box:fontcolor=white:fontsize=45:enable='between(t,0,2):y=110:x=(w-tw)/2'"
line22="drawtext=text='$S22':$box:fontcolor=white:fontsize=45:enable='between(t,0,2):y=175:x=(w-tw)/2'"
line3="drawtext=text='$S3':$box:fontcolor=white:fontsize=40:enable='between(t,0,2):y=h-70:x=(w-tw)/2'"
line4="drawtext=text='ffmpeg 加速${speed} 音${a} 视${v} ${fps}fps $datefull':$box:fontcolor=white:fontsize=10:enable='between(t,0,15):y=h-th-1:x=w-tw-1'"

if [ $speed != 1 ]
then
	input=${filename_withoutext}_speed$speed.mp4
	if [ ! -f $input ]; then
		ffmpeg -y -i $1 -ss 0  -b:a $a -strict -2 -b:v $v -filter_complex "setpts=PTS/${speed};atempo=${speed}" ${filename_withoutext}_speed${speed}.mp4
	fi
	audio="-acodec copy"
fi

if [ $delay != 0 ]
then
	ffmpeg -y -i $input -itsoffset $delay -i $input -map 0:v -map 1:a -vcodec copy -acodec copy ${filename_withoutext}_speed${speed}_delay${delay}.mp4
	input=${filename_withoutext}_speed${speed}_delay${delay}.mp4
fi

if [ $volume != 0 ]
then
	ffmpeg -y -i $input -vcodec copy -strict -2 -af "volume=${volume}" ${filename_withoutext}_speed${speed}_delay${delay}_volume${volume}.mp4
	input=${filename_withoutext}_speed${speed}_delay${delay}_volume${volume}.mp4
fi

if [ "a$sub" != "a" ]
then
	ffmpeg -y -ss $ss -i $input \
	    $sub \
	    $audio \
	    -b:v ${v} -r ${fps} ${filename_withoutext}_sub.mp4
	input=${filename_withoutext}_sub.mp4
	audio="-acodec copy"
fi

if [ $n -gt 1 ]
then
	ffmpeg -y -i $input -ss $ss $ac $audio -b:v ${v} -r ${fps} -strict -2 -f segment -segment_time $len -reset_timestamps 1 -map 0 ${filename_withoutext}_%d.mp4

	for i in `seq 1 ${n}`;
	do
	  let j=${i}-1
	  if [ ! -f ${filename_withoutext}_${j}.mp4 ]; then
	    break
	  fi

	  ffmpeg -y -analyzeduration 60000 -i ${filename_withoutext}_${j}.mp4 -vf \
		  "$line1,$line2\
		  ,drawtext=text='$i/$n':$box:fontcolor=white:fontsize=50:enable='between(t,0,2):y=180:x=(w-tw)/2'\
		  ,$line3,$line4" \
	    -acodec copy -b:v ${v} -r ${fps} /home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}__${i}_of_${n}.mp4

	  rm -f ${filename_withoutext}_${j}.mp4

	done
else
	  ffmpeg -y -ss $ss -i $input -vf \
		  "$line1,$line2, $line22\
		  ,$line3,$line4" \
	    $ac $audio -b:v ${v} -r ${fps} /home/public_share/${datefull}_${filename_withoutext}_${speed}_$a$v${fps}.mp4

fi
