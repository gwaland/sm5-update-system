#!/bin/bash
_PACKAGES="mesa-common-dev libglu1-mesa-dev libxtst-dev  libxrandr-dev libpng12-dev  libjpeg8-dev zlib1g-dev  libbz2-dev libogg-dev  libvorbis-dev libc6-dev yasm  libasound-dev  libpulse-dev  libjack-dev libglew1.6-dev binutils-dev  libgtk2.0-dev  libmad0-dev automake  nvidia-173 xserver-xorg git gawk mesa-utils xinit alsa-base "
_USER=$(whoami)
_GIT_SM="https://github.com/stepmania/stepmania.git"
_GIT_PIUIO="https://github.com/djpohly/piuio.git"
#change this to master to use the new io. (at this time lights aren't supported.
_PIUIO_BRANCH="legacy"

#generate keys and directories needed.
ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
mkdir -p ~/sm5-install
mkdir -p ~/repo/piuio
mkdir -p ~/repo/sm5
mkdir -p ~/repo/theme
mkdir -p ~/repo/songs
mkdir -p ~/Themes/.md5sum

#themes are not automatically pulled
#Grab stepmania and piuio sources
cd ~
git clone $_GIT_SM
git clone $_GIT_PIUIO -b $_PIUIO_BRANCH

#create link to updater (Assuming this is in ~/sm5-update-system for now. 
ln -s ~/sm5-update-system/update-server.sh ~/update.sh
(crontab -l 2>/dev/null; echo "  0 *  *   *   *  bash /home/piu/update.sh") | crontab -

#install packages
sudo apt-get update
sudo apt-get -y install $_PACKAGES

echo 'SM_PATH=/home/piu/stepmania' >  ~/.sm5-server.rc
echo 'SM_INSTALL_PATH=/home/piu/sm5-install' >> ~/.sm5-server.rc
echo 'PIUIO_PATH=/home/piu/piuio' >> ~/.sm5-server.rc
echo '#THEME_PATH=/home/piu/Themes/PIU-Delta-GW' >> ~/.sm5-server.rc
echo 'THEME_PATH=/home/piu/Themes' >> ~/.sm5-server.rc
echo 'SM_REPO_PATH=/home/piu/repo/sm5' >> ~/.sm5-server.rc
echo 'THEME_REPO_PATH=/home/piu/repo/theme' >> ~/.sm5-server.rc
echo 'PIUIO_REPO_PATH=/home/piu/repo/piuio' >> ~/.sm5-server.rc
echo '#usage display' >> ~/.sm5-server.rc

#Finally force an update on all options
~/update.sh -vstp

