# Obtain your youtube API key for free at google developer console: https://www.youtube.com/watch?v=Im69kzhpR3I
# The following key is locked down to a private IP address and must be changed before use.
g_GoogleApiKey=AIzaSyCyaIc6wpatDoeuPVsET_2_-yh5arU27NA
g_MainHost=144.202.87.139	# Primary host for most channels, change to your host
#g_Host1=.8.8.8	# Second host for some channels, change to your host

g_YtdailyHome=.
g_CacheRoot=$g_YtdailyHome/cache
g_HostRoot=$g_YtdailyHome/host
g_MainHostRoot=$g_HostRoot/$g_MainHost
g_GlobalApiSleep=0
g_DefaultHoursToGoBack=24		# How many hours to look back when crawling for videos
g_MaxItemsPerChannel=100

[[ -d $g_CacheRoot ]] || mkdir $g_CacheRoot
[[ -d $g_HostRoot ]] || mkdir $g_HostRoot
[[ -d $g_MainHostRoot ]] || mkdir $g_MainHostRoot

g_VirtualChannelsOnly="NT1"
g_ChannelsSimple="YP"
g_ChannelsComplex="NT"
g_Channels="$g_ChannelsSimple $g_ChannelsComplex"
g_VirtualChannels="$g_VirtualChannelsOnly $g_ChannelsSimple"

declare -A g_ChannelName
declare -A g_ChannelId
declare -A g_ChannelHost
declare -A g_ChannelHoursToGoBack

g_ChannelId[NT]=UCdbvc-yJ4JQjNGTgFiJIZNA
g_ChannelName[NT1]=新唐人电视
g_ChannelHost[NT1]=$g_MainHost
#
# Virtual channel definitions for N1
#
function Selector_NT1 {
	grep "环球直击\|严真点评\|时事小品" $1
}

g_ChannelId[YP]=UCLXvE-XNRIs7_GzEsEmMiRw
g_ChannelName[YP]=李一平
g_ChannelHost[YP]=$g_MainHost
