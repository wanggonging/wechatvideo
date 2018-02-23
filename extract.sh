id=UCtAIPjABiQD3qjlEl1T5VpA
wget https://www.youtube.com/channel/$id/videos -O - | sed '/\<title\>/,$!d' | pup 'a[dir="ltr"]' | grep watch | pup "a json{}" | jq '.[]|.href' | cut -b 11-21


