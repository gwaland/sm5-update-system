#!/bin/bash
_PACKAGES="mesa-common-dev libglu1-mesa-dev libxtst-dev  libxrandr-dev libpng12-dev  libjpeg8-dev zlib1g-dev  libbz2-dev libogg-dev  libvorbis-dev libc6-dev yasm  libasound-dev  libpulse-dev  libjack-dev libglew1.6-dev binutils-dev  libgtk2.0-dev  libmad0-dev automake  nvidia-173 xserver-xorg git gawk mesa-utils xinit alsa-base "
_USER=$(whoami)
_GIT_SM="https://github.com/stepmania/stepmania.git"
_GIT_PIUIO="https://github.com/djpohly/piuio.git"
_GIT_CONSENSUAL="https://github.com/kyzentun/consensual.git"
#change this to master to use the new io. (at this time lights aren't supported.
_PIUIO_BRANCH="legacy"

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPT_PATH=`dirname $SCRIPT`


#spinner class (probably needs to be taken out or a -q -v option added to enable it.
spinner()
{
        local pid=$1
        local delay=0.75
        local spinstr='|/-\'
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
                if [ $VERBOSE = 1 ]; then
                        local temp=${spinstr#?}
                        printf " [%c]  " "$spinstr"
                        local spinstr=$temp${spinstr%"$temp"}
                        sleep $delay
                        printf "\b\b\b\b\b\b"
                fi
        done
        printf "    \b\b\b\b"
}


#interactive portion
_EXIT_STATUS=1
while [ $_EXIT_STATUS -ne 0 ]; do 
	PASSWORD=$(whiptail --passwordbox "What is your password for $_USER?" 8 78 --title "Sudo Password" 3>&1 1>&2 2>&3)
	echo $PASSWORD | sudo -S echo > /dev/null
	_EXIT_STATUS=$?
done
SM_PATH=$(whiptail --inputbox "Path for stepmania source installation" 8 78 /home/$_USER/stepmania --title "Stepmania Source Path" 3>&1 1>&2 2>&3)
SM_INSTALL_PATH=$(whiptail --inputbox "Path for stepmania package installation" 8 78 /home/$_USER/sm5-install --title "Stepmania package install Path" 3>&1 1>&2 2>&3)
PIUIO_PATH=$(whiptail --inputbox "Path for piuio source installation" 8 78 /home/$_USER/piuio --title "PIUIO Source Path" 3>&1 1>&2 2>&3)
THEME_PATH=$(whiptail --inputbox "Path for Theme installations" 8 78 /home/$_USER/Themes --title "Theme Source Path" 3>&1 1>&2 2>&3)
SM_REPO_PATH=$(whiptail --inputbox "Path for the Stepmania Repository" 8 78 /home/$_USER/repo/sm5 --title "Stepmania Repository Path" 3>&1 1>&2 2>&3)
THEME_REPO_PATH=$(whiptail --inputbox "Path for the Themes Repository" 8 78 /home/$_USER/repo/theme --title "Themes Repository Path" 3>&1 1>&2 2>&3)
PIUIO_REPO_PATH=$(whiptail --inputbox "Path for the PIUIO Repository" 8 78 /home/$_USER/repo/piuio --title "PIUIO Repository Path" 3>&1 1>&2 2>&3)
SONG_REPO_PATH=$(whiptail --inputbox "Path for the songs Repository" 8 78 /home/$_USER/repo/songs --title "Songs Repository Path" 3>&1 1>&2 2>&3)


#get the sudo stuff out of the way first.
echo "updating APT"
echo -e "$PASSWORD\n" | sudo -S apt-get -qq update > /dev/null 2>&1 &
spinner $!

echo "Installing Packages"
echo -e "$PASSWORD\n" | sudo -S apt-get -qq -y install $_PACKAGES > /dev/null 2>&1 &
spinner $!


#generate keys and directories needed.
ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
mkdir -p $SM_INSTALL_PATH
mkdir -p $PIUIO_REPO_PATH
mkdir -p $SM_REPO_PATH
mkdir -p $THEME_REPO_PATH
mkdir -p $SONG_REPO_PATH 
mkdir -p $THEME_PATH/.md5sum

#themes are not automatically pulled
#Grab stepmania and piuio sources
git clone $_GIT_SM $SM_PATH
git clone $_GIT_PIUIO -b $_PIUIO_BRANCH $PIUIO_PATH
git clone $_GIT_CONSENSUAL $THEME_PATH/consensual/

#create link to updater (Assuming this is in ~/sm5-update-system for now. 
ln -s $SCRIPT_PATH/update-server.sh /home/$_USER/update.sh
(crontab -l 2>/dev/null; echo "  0 *  *   *   *  bash /home/$_USER/update.sh") | crontab -


echo "SM_PATH=$SM_PATH" >  ~/.sm5-server.rc
echo "SM_INSTALL_PATH=$SM_INSTALL_PATH" >> ~/.sm5-server.rc
echo "PIUIO_PATH=$PIUIO_PATH" >> ~/.sm5-server.rc
echo "THEME_PATH=$THEME_PATH" >> ~/.sm5-server.rc
echo "SM_REPO_PATH=$SM_REPO_PATH" >> ~/.sm5-server.rc
echo "THEME_REPO_PATH=$THEME_REPO_PATH" >> ~/.sm5-server.rc
echo "PIUIO_REPO_PATH=$PIUIO_REPO_PATH" >> ~/.sm5-server.rc
echo "SONG_REPO_PATH=$SONG_REPO_PATH" >> ~/.sm5-server.rc

#Finally force an update on all options
/home/$_USER/update.sh -vstp

