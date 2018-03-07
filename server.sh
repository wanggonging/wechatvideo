ip=$1

if [ "$ip" == "" ]; then
	echo Usage: $0 ip
	exit 1
fi

ssh root@$ip mkdir .ssh
scp ~/authorized_keys root@$ip:~/.ssh
scp provision.sh root@$ip:~
ssh root@$ip ./provision.sh

