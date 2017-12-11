#youtube-dl -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' -o $1 $2
youtube-dl -f 'bestvideo[width<=740]+bestaudio/best[width<=740]' -o $1 $2

