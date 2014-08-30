#!/bin/bash
_PACKAGES='binutils git libmad0 libvorbisfile3 nvidia-173 libglu1-mesa libglew1.10 libjack0 xserver-xorg xinit alsa'
_SERVER=piu-server.home.priv
_SERVER_USER=piu
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



ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
ssh-keyscan -H $_SERVER >> ~/.ssh/known_hosts
echo "We're going to install the ssh key on the server.  You'll need the password for your server's $_SERVER_USER now."
cat ~/.ssh/id_rsa.pub | ssh $_SERVER_USER@$_SERVER "cat >> ~/.ssh/authorized_keys"

ln -s ~/sm5-update-system/update-client.sh ~/update.sh
mkdir ~/Songs
mkdir -p ~/sm5/Themes
mkdir -p ~/sm5/Save

echo "Doing all the sudo stuff needed in one chunk.  Put in your $(whoami) password here."
sudo ln -sf /dev/null /etc/udev/rules.d/70-persistent-net.rules
sudo sed -i s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"nomodeset\"/g /etc/default/grub
sudo sed -i s/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/g /etc/default/grub
sudo sed -i s/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=640x480/g /etc/default/grub
sudo update-grub
sudo sed -i s/exi/#exi/g /etc/rc.local
sudo  sh -c 'echo chmod a+wrx /dev/piuio0 >> /etc/rc.local'
sudo sh -c 'echo exit 0 >> /etc/rc.local'
sudo sed -i s/exec/#exec/g /etc/init/tty1.conf
sudo sh -c 'echo "exec /bin/login -f piu tty1 </dev/tty1 >/dev/tty1 2>&1" >> /etc/init/tty1.conf'
sudo usermod -G audio $_USER
echo updating apt.
sudo apt-get -qq update > /dev/null 2>&1 &
spinner $!
echo installing packages.
sudo apt-get -qq -y install $_PACKAGES > /dev/null 2>&1 &
spinner $!

sudo alsa force-reload

echo 'exec /home/piu/stepmania.sh' > ~/.xinitrc; chmod +x ~/.xinitrc
echo '#!/bin/bash' > ~/stepmania.sh; echo 'cd ~/sm5' >> ~/stepmania.sh; echo './stepmania' >> ~/stepmania.sh; chmod +x ~/stepmania.sh
echo 'if (  last | grep -e $(whoami) -e reboot | head -2 | grep -q reboot ); then' >> ~/.profile
echo '     ~/update.sh' >> ~/.profile
echo 'fi' >> ~/.profile
echo 'if [ -z "$DISPLAY" ] && [ $(tty) == /dev/tty1 ]; then' >> ~/.profile
echo '    startx' >> ~/.profile
echo 'fi' >> ~/.profile

~/update.sh
