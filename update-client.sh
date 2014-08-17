#/bin/bash
#rsync -avrc -e ssh piu-server:~/Songs/* /home/piu/Songs/
#cp -rsf /home/piu/Songs/ /home/piu/sm5/
_SERVER=piu-server.home.priv
_REMOTE_SONG_PATH='/home/piu/Songs/'
_REMOTE_THEME_PATH=/var/www/html/*current*
_REMOTE_SM_PATH=/var/www/html/*current*
_LOCAL_UPDATE_PATH=/home/piu/new/
_LOCAL_SONG_PATH=/home/piu/Songs/
_LOCAL_SM_PATH=/home/piu/sm5/

progress()
{
        local pid=$1
        local delay=0.75
        local spinstr='|/-\'
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
		local out=$(tail -1 /tmp/prog | strings|tail -1 | awk '{print $2}' | tr -d '%')
		echo $out
		sleep 3
        done
}
#updateclient <server path> <local path> '<description>'
updateclient ()
{
rsync -Lazr --info=progress2 -e ssh $_SERVER:$1 $2 > /tmp/prog  &
progress $! |  whiptail --title "$3 Updates" --gauge "Downloading new $3" 7 70 0
}
#update Songs. 
updateclient $_REMOTE_SONG_PATH $_LOCAL_SONG_PATH 'Songs'
cp -rsf /home/piu/Songs /home/piu/sm5/

#update stepmania from server.
updateclient $_REMOTE_SM_PATH $_LOCAL_UPDATE_PATH 'Stepmania Software'

cmp -s /home/piu/new/stepmania-build-current.md5sum /home/piu/installed/stepmania-build-current.md5sum 
if [ $? -eq 0 ]; then
	echo "SM is up to date!"
else
	echo "installing updated Stepmania."
	mv /home/piu/sm5 /home/piu/sm5.backup
	mkdir /home/piu/sm5
	cd /home/piu/sm5
	tar xf /home/piu/new/stepmania-build-current.tar.gz
	rm -rf /home/piu/sm5/Save
	touch portable.ini
	mkdir Save
	cp -rf /home/piu/sm5.backup/Save/* /home/piu/sm5/Save/
	cp -rsf /home/piu/Songs /home/piu/sm5
	cp /home/piu/new/stepmania-build-current.md5sum /home/piu/installed/stepmania-build-current.md5sum
        ls -1 /home/piu/sm5/Themes > /home/piu/sm5/theme.exclude
	rsync -avr --exclude-from /home/piu/sm5/theme.exclude /home/piu/sm5.backup/Themes/ /home/piu/sm5/Themes/

fi


