#!/bin/bash
_PACKAGES='sshpass binutils libpulse0 git libmad0 libvorbisfile3 nvidia-173 libglu1-mesa libglew1.10 libjack0 xserver-xorg xinit alsa'
_USER=$(whoami)


spinner()
{
        local pid=$1
        local delay=0.75
        local spinstr='|/-\'
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
                local temp=${spinstr#?}
                printf " [%c]  " "$spinstr"
                local spinstr=$temp${spinstr%"$temp"}
                sleep $delay
                printf "\b\b\b\b\b\b"
        done
        printf "    \b\b\b\b"
}


#interactive portion
_EXIT_STATUS=1
while [ $_EXIT_STATUS -ne 0 ]; do
        _PASSWORD=$(whiptail --passwordbox "What is your password for $_USER?" 8 78 --title "Sudo Password" 3>&1 1>&2 2>&3)
        echo $_PASSWORD | sudo -S echo > /dev/null
        _EXIT_STATUS=$?
done
echo "updating APT"
echo -e "$PASSWORD\n" | sudo -S apt-get -qq update > /dev/null 2>&1 &
spinner $!

echo "Installing sshpass"
echo -e "$PASSWORD\n" | sudo -S apt-get -qq -y install sshpass > /dev/null 2>&1 &
spinner $!


#get server settings.
_SERVER=$(whiptail --inputbox "What is the IP or hostname of the Server?" 8 78 sm5-server --title "Server Name" 3>&1 1>&2 2>&3)
ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
ssh-keyscan -H $_SERVER >> ~/.ssh/known_hosts

_EXIT_STATUS=1
while [ $_EXIT_STATUS -ne 0 ]; do
	_SERVER_USER=$(whiptail --inputbox "What is the username for the server?" 8 78 piu --title "Server Username" 3>&1 1>&2 2>&3)
	_SERVER_PASSWORD=$(whiptail --passwordbox "What is the password for the server?" 8 78 --title "Server Password" 3>&1 1>&2 2>&3)
        export SSHPASS=$_SERVER_PASSWORD
        sshpass -e ssh $_SERVER_USER@$_SERVER echo
        _EXIT_STATUS=$?
done
cat ~/.ssh/id_rsa.pub | sshpass -e ssh $_SERVER_USER@$_SERVER "cat >> ~/.ssh/authorized_keys"

#get server settings. 
scp $_SERVER_USER@$_SERVER:~/.sm5-server.rc /tmp/serversettings
if [ -s /tmp/serversettings ]; then
	. /tmp/serversettings
	_REMOTE_SM_PATH=$SM_REPO_PATH
	_REMOTE_THEME_PATH=$THEME_REPO_PATH
	_REMOTE_PIUIO_PATH=$PIUIO_REPO_PATH
	_REMOTE_SONG_PATH=$SONG_REPO_PATH
else
	echo "Issue with getting server settings.  Try again."
	exit 1
fi

unset SSHPASS

_LOCAL_UPDATE_PATH=$(whiptail --inputbox "Path to store update files?" 8 78 /home/$_USER/new --title "Update Path" 3>&1 1>&2 2>&3)
_LOCAL_SONG_PATH=$(whiptail --inputbox "Path to store song files?" 8 78 /home/$_USER/Songs --title "Song Path" 3>&1 1>&2 2>&3)
_LOCAL_BACKUP_PATH=$(whiptail --inputbox "Path to store Backup files?" 8 78 /home/$_USER/backup --title "Backup Path" 3>&1 1>&2 2>&3)
_LOCAL_SM_PATH=$(whiptail --inputbox "Path to store stepmania files?" 8 78 /home/$_USER/sm5 --title "Stepmania Path" 3>&1 1>&2 2>&3)




#ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
#ssh-keyscan -H $_SERVER >> ~/.ssh/known_hosts
#echo "We're going to install the ssh key on the server.  You'll need the password for your server's $_SERVER_USER now."
#cat ~/.ssh/id_rsa.pub | ssh $_SERVER_USER@$_SERVER "cat >> ~/.ssh/authorized_keys"

ln -s ~/sm5-update-system/update-client.sh ~/update.sh
mkdir -p $_LOCAL_SONG_PATH
mkdir -p $_LOCAL_SM_PATH/Themes
mkdir -p $_LOCAL_SM_PATH/Save
mkdir -p $_LOCAL_UPDATE_PATH
mkdir -p $_LOCAL_BACKUP_PATH

#echo "Doing all the sudo stuff needed in one chunk.  Put in your $(whoami) password here."
echo -e "$PASSWORD\n" | sudo -S ln -sf /dev/null /etc/udev/rules.d/70-persistent-net.rules
echo -e "$PASSWORD\n" | sudo -S sed -i s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"nomodeset\"/g /etc/default/grub
echo -e "$PASSWORD\n" | sudo -S sed -i s/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/g /etc/default/grub
echo -e "$PASSWORD\n" | sudo -S sed -i s/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=640x480/g /etc/default/grub
echo -e "$PASSWORD\n" | sudo -S update-grub
echo -e "$PASSWORD\n" | sudo -S sed -i s/exi/#exi/g /etc/rc.local
echo -e "$PASSWORD\n" | sudo -S sh -c 'echo chmod a+wrx /dev/piuio0 >> /etc/rc.local'
echo -e "$PASSWORD\n" | sudo -S sh -c 'echo exit 0 >> /etc/rc.local'
echo -e "$PASSWORD\n" | sudo -S sed -i s/exec/#exec/g /etc/init/tty1.conf
echo -e "$PASSWORD\n" | sudo -S sh -c 'echo "exec /bin/login -f piu tty1 </dev/tty1 >/dev/tty1 2>&1" >> /etc/init/tty1.conf'
echo -e "$PASSWORD\n" | sudo -S usermod -a -G audio $_USER

#echo updating apt.
#sudo apt-get -qq update > /dev/null 2>&1 &
#spinner $!
echo installing packages.
echo -e "$PASSWORD\n" | sudo -S apt-get -qq -y install $_PACKAGES > /dev/null 2>&1 &
#spinner $!

echo -e "$PASSWORD\n" | sudo -S alsa force-reload

echo 'exec /home/piu/stepmania.sh' > ~/.xinitrc; chmod +x ~/.xinitrc
echo '#!/bin/bash' > ~/stepmania.sh; echo 'cd ~/sm5' >> ~/stepmania.sh; echo './stepmania' >> ~/stepmania.sh; chmod +x ~/stepmania.sh
echo 'if (  last | grep -e $(whoami) -e reboot | head -2 | grep -q reboot ); then' >> ~/.profile
echo '     ~/update.sh' >> ~/.profile
echo 'fi' >> ~/.profile
echo 'if [ -z "$DISPLAY" ] && [ $(tty) == /dev/tty1 ]; then' >> ~/.profile
echo '    startx' >> ~/.profile
echo 'fi' >> ~/.profile


#build ~/.sm5-client.rc
echo "_SERVER=$_SERVER" > ~/.sm5-client.rc
echo "_REMOTE_SONG_PATH=$_REMOTE_SONG_PATH'" >> ~/.sm5-client.rc
echo "_REMOTE_THEME_PATH=$_REMOTE_THEME_PATH" >> ~/.sm5-client.rc
echo "_REMOTE_SM_PATH=$_REMOTE_SM_PATH*" >> ~/.sm5-client.rc
echo "_REMOTE_PIUIO_PATH=$_REMOTE_PIUIO_PATH" >> ~/.sm5-client.rc
echo "_LOCAL_UPDATE_PATH=$_LOCAL_UPDATE_PATH" >> ~/.sm5-client.rc
echo "_LOCAL_SONG_PATH=$_LOCAL_SONG_PATH" >> ~/.sm5-client.rc
echo "_LOCAL_SM_PATH=$_LOCAL_SM_PATH" >> ~/.sm5-client.rc



~/update.sh
