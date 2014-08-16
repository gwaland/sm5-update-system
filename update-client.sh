#!/bin/bash
#rsync -avrc -e ssh piu-server:~/Songs/* /home/piu/Songs/
#cp -rsf /home/piu/Songs/ /home/piu/sm5/

progress()
{
        local pid=$1
        local delay=0.75
        local spinstr='|/-\'
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
		local out=$(tail -1 /tmp/prog | strings | awk '{print $2}' | tr -d '%')
		echo $out
		sleep 5
        done
}
rsync -azr --info=progress2 -e ssh piu-server:~/Songs/* /home/piu/Songs/ > /tmp/prog  &
progress $! #| uniq #| whiptail --title "Son Updates" --gauge "Downloading new songs" 20 70 0
