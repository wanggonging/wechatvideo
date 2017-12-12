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
#len=900 && a=40k && v=130k && fps=25  # 15min
len=800 && a=40k && v=145k && fps=25  # 15min
#len=700 && a=40k && v=170k && fps=25  # 15min
#len=600 && a=40k && v=200k && fps=25  # 15min
#len=930 && a=40k && v=120k && fps=25  # 20MB
#len=1030 && a=40k && v=100k && fps=25  # 20MB
#len=1000 && a=40k && v=100k && fps=25  # 20MB
#len=1180 && a=30k && v=100k && fps=25  # 20MB
#len=1180 && a=44k && v=400k && fps=30  # 20MB
speed=1
volume=0
delay=0
ss=0
S1="唐柏桥"
S2="舊金山法輪功集會上的演講"
S3="2016.10.25"
#S1="辛灝年"
#S1="縱論天下陳破空"
#S1="建平建言"
#S1="小民之心"
#S1="点点今天事"
#S1="江森哲"
#S1="姜维平读报点评"
#S1="建民论推墙105"
#S1="文昭谈古论今"
#S3="2013.10.31"
#S1="大师兄"
#S1="明镜火拍"
#S1="明镜火拍 網言網事"
#S1="美国之音 时事大家谈"
#S1="华涌12.11报平安"
#S1="朱万利"
#S1="新唐人"
#S1="美国之音 海峡论谈"
#S1="小哥谈政事"
#S1="美国之音 世界人权日"
#S1="华涌 世界人权日报平安"
#S1="全能神教會"
#S1="明镜火拍 法治與社會"
#S1="零点时刻"
#S1="自由亚洲 中国热评"
#S1="CivilResistance.net"
#S1="华涌逃亡中"
#S1="美国之音 焦点对话"
#S1="博闻焦点 徐友渔" && ss=6
#S1="自由亚洲 品阅经典"
#S1="雷人网事"
#S1="黄河边播报"
#S1="解密时刻"
#S1="陈光诚" && delay=0.6
#S1="蝴蝶视点"
#S1="经世济民夏业良"
#S1="艾未未工作室"
#S2="吴东海曝习近平 第3集"
#---------------------------------------------
#S2="感到危险，江泽民通过艺人报平安"
#S2="新一路口全记录 ${filename_withoutext}/20"
#S22="北京市大兴区西红门镇"
#S2="村民堵路事件始末 ${filename_withoutext}/10"
#S2="北京华涌，是中国当代英雄"
#S2="朝鲜问题"
#S2="三类国民和未来国家建设力量"
#S2="北京遭驱逐外地人要人权"
#S2="只愿做一只说真话的小蚂蚁！"
#S2="如何促进发生颠覆中共的新兵谏"
#S2="澳大利亚反对中国干涉内政"
#S2="807專案炮製麥當勞命案？"
#S2="'任大炮'重出江湖，炮口对准谁？"
#S2="非法滞留中国的非裔人群现状和问题"
#S2="大跃进 vs 煤改气"
#S2="我为何反共？(1)职业经历中的忧思"
#S2="王岐山秘书高升，李长春大秘被抓？"
#S2="拆除邓小平题词"
#S22="习近平朝正确方向迈出第三步？"
#S2="川普12月18日斩首金三？"
#S22="金正恩生气后果严重 习近平是否还有机会"
#S2="华涌12月9日报平安"
#S22="朋友家被警察搜查，不会出国"
#S2="滕彪 驱逐低端人口的制度根源"
#S2="中国未来制度建设"
#S2="网络主权 煤改气 中共里外折腾永无止境？"
#S2="朝鮮戰爭一觸即發 等"
#S2="百姓应该烧煤气 饥民何不食肉糜"
#S2="李克强力促国务院下文件"
#S2="老王回归"
#S22="是独挑一头还是混合包圆？"
#S2="华涌12/08报平安"
#S2="被警察追捕 思念家人"
#S2="小咖啡馆打烊前公开信"
#S2="东西两朝鲜 马克思主义"
#S22="被追捕 已顺利撤离北京"
#S22="请求大家勇敢地站出来说真话"
#S22="《致全世界自由国度的人民》"

date=`TZ="UTC-8" date "+%y%m%d%H%M"`
DURATION_HMS=$(ffmpeg -i "$input" 2>&1 | grep Duration | cut -f 4 -d ' ')
DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
DURATION_S=$(echo "$DURATION_HMS" | cut -d ':' -f 3 | cut -d '.' -f 1)
DURATION=`echo "(( $DURATION_H * 60 + $DURATION_M ) * 60 + $DURATION_S) / $speed" | bc -l`
D=`printf %.0f $DURATION`
let "n= (($D - 1) / $len) + 1"
echo "$D / $len = $n | $S1 | $S2 | $S22"
read -n1 -r -p "Press any key to continue..." key

box="box=1:boxcolor=black@0.6:boxborderw=1"
line1="drawtext=text='$S1':$box:fontcolor=white:fontsize=40:enable='between(t,0,2):y=40:x=(w-tw)/2'"
line2="drawtext=text='$S2':$box:fontcolor=white:fontsize=45:enable='between(t,0,2):y=110:x=(w-tw)/2'"
line22="drawtext=text='$S22':$box:fontcolor=white:fontsize=45:enable='between(t,0,2):y=175:x=(w-tw)/2'"
line3="drawtext=text='$S3':$box:fontcolor=white:fontsize=40:enable='between(t,0,2):y=h-110:x=(w-tw)/2'"
line4="drawtext=text='ffmpeg 加速${speed} 音${a} 视${v} ${fps}fps $date':$box:fontcolor=white:fontsize=10:enable='between(t,0,15):y=h-th-1:x=w-tw-1'"

if [ $speed != 1 ]
then
	input=${filename_withoutext}_speed$speed.mp4
	if [ ! -f $input ]; then
		ffmpeg -y -i $1 -ss 0  -b:a 80k -strict -2 -b:v 200k -filter_complex "setpts=PTS/${speed};atempo=${speed}" ${filename_withoutext}_speed${speed}.mp4
	fi
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

if [ $n -gt 1 ]
then
	ffmpeg -y -i $input -ss $ss -b:a ${a} -b:v ${v} -r ${fps} -strict -2 -f segment -segment_time $len -reset_timestamps 1 -map 0 ${filename_withoutext}_%d.mp4

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
	    -ac 1 -b:a ${a} -strict -2 -b:v ${v} -r ${fps} /home/public_share/${date}_${filename_withoutext}_${speed}_$a$v${fps}__${i}_of_${n}.mp4

#	  rm -f ${filename_withoutext}_${j}.mp4

	done
else
	  ffmpeg -y -ss $ss -i $input -vf \
		  "$line1,$line2, $line22\
		  ,$line3,$line4" \
	    -ac 1 -b:a ${a} -strict -2 -b:v ${v} -r ${fps} /home/public_share/${date}_${filename_withoutext}_${speed}_$a$v${fps}.mp4

fi
