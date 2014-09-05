#/bin/bash
#import settings.
if [ -f ~/.sm5-client.rc ]; then
        . ~/.sm5-client.rc
else
        echo "configuration missing!"
        exit 1
fi
#verify settings import

#whiptail based progress bar for rsync. 
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


#update Songs and create the symlinks. 
updateclient $_REMOTE_SONG_PATH/ $_LOCAL_SONG_PATH 'Songs'
cp -rsf /home/piu/Songs /home/piu/sm5/

#grab potential updates for stepmania.
updateclient $_REMOTE_SM_PATH/ $_LOCAL_UPDATE_PATH/sm5 'Stepmania Software'

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

#grab themes and drop them in PACKAGES directory. 
updateclient $_REMOTE_THEME_PATH/ $_LOCAL_SM_PATH/Packages 'Stepmania Themes'

