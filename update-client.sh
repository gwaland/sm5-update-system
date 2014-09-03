#/bin/bash
#rsync -avrc -e ssh piu-server:~/Songs/* /home/piu/Songs/
#cp -rsf /home/piu/Songs/ /home/piu/sm5/
#_SERVER=piu-server.home.priv
#_REMOTE_SONG_PATH='/home/piu/repo/songs/'
#_REMOTE_THEME_PATH=/home/piu/repo/theme/*current*
#_REMOTE_SM_PATH=/home/piu/repo/sm5/*current*
#_REMOTE_PIUIO_PATH=/home/piu/repo/piuio/*current*
#_LOCAL_UPDATE_PATH=/home/piu/new/
#_LOCAL_SONG_PATH=/home/piu/Songs/
#_LOCAL_SM_PATH=/home/piu/sm5/
. ~/.sm5-client.rc

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
rsync -Lazr --delete --info=progress2 -e ssh $_SERVER:$1 $2 > /tmp/prog  &
progress $! |  whiptail --title "$3 Updates" --gauge "Downloading new $3" 7 70 0
}
#update Songs. 
updateclient $_REMOTE_SONG_PATH $_LOCAL_SONG_PATH 'Songs'
cp -rsf /home/piu/Songs /home/piu/sm5/

#update stepmania from server.
updateclient $_REMOTE_SM_PATH $_LOCAL_UPDATE_PATH/sm5 'Stepmania Software'

cmp -s $_LOCAL_UPDATE_PATH/sm5/stepmania-build-current.md5sum $_LOCAL_UPDATE_PATH/installed/stepmania-build-current.md5sum 
if [ $? -eq 0 ]; then
	echo "SM is up to date!"
else
	_NOW=$(date +%Y%m%d%H%M)
	echo "installing updated Stepmania."
	mv $_LOCAL_SM_PATH $_LOCAL_BACKUP_PATH/sm5.$_NOW
	mkdir $_LOCAL_SM_PATH
	cd $_LOCAL_SM_PATH
	tar xf $_LOCAL_UPDATE_PATH/sm5/stepmania-build-current.tar.gz
	rm -rf $_LOCAL_SM_PATH/Save
	touch portable.ini
	mkdir Save
	cp -rf $_LOCAL_BACKUP_PATH/sm5.$_NOW/Save/* $_LOCAL_SM_PATH/Save/
	cp -rsf $_LOCAL_SONG_PATH/* $_LOCAL_SM_PATH/Songs/
	cp $_LOCAL_UPDATE_PATH/sm5/stepmania-build-current.md5sum $_LOCAL_UPDATE_PATH/installed/stepmania-build-current.md5sum
        ls -1 $_LOCAL_SM_PATH/Themes > $_LOCAL_SM_PATH/theme.exclude
	rsync -avr --exclude-from $_LOCAL_SM_PATH/theme.exclude $_LOCAL_BACKUP_PATH/sm5.$_NOW/Themes/ $_LOCAL_SM_PATH/Themes/

fi


