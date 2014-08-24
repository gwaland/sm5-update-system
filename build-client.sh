#!/bin/bash
_PACKAGES='binutils git libmad0 libvorbisfile3 nvidia-173 libglu1-mesa libglew1.10 libjack0 xserver-xorg xinit'
_SERVER="piu-server"
_SERVER_USER="piu"

ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | ssh $SERVER_USER@$_SERVER "cat >> ~/.ssh/authorized_keys"

ln -s ~/sm5-update-system/update-client.sh ~/update.sh
mkdir ~/Songs
mkdir -p ~/sm5/Themes
mkdir -p ~/sm5/Save

sudo ln -sf /dev/null /etc/udev/rules.d/70-persistent-net.rules
sudo sed -i s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"nomodeset\"/g /etc/default/grub
sudo sed -i s/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/g /etc/default/grub
sudo sed -i s/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=640x480/g /etc/default/grub
sudo update-grub
sudo sed -i s/exit 0//g /etc/rc.local
sudo  echo 'chmod a+wrx /dev/piuio0' >> /etc/rc.local
sudo echo 'exit 0' >> /etc/rc.local
sudo apt-get update
sudo apt-get install $_PACKAGES
sudo sed -i s/exec/#exec/g /etc/init/tty1.conf
sudo echo 'exec /bin/login -f piu tty1 </dev/tty1 >/dev/tty1 2>&1' >> /etc/init/tty1.conf
echo 'exec /home/piu/stepmania.sh' > ~/.xinitrc; chmod +x ~/.xinitrc
echo '#!/bin/bash' > ~/stepmania.sh; echo 'cd ~/sm5' >> ~/stepmania.sh; echo './stepmania' >> ~/stepmania.sh; chmod +x ~/stepmania.sh
echo 'if (  last | grep -e $(whoami) -e reboot | head -2 | grep -q reboot ); then' >> ~/.profile
echo '     ~/update.sh' >> ~/.profile
echo 'fi' >> ~/.profile
echo 'if [ -z "$DISPLAY" ] && [ $(tty) == /dev/tty1 ]; then' >> ~/.profile
echo '    startx' >> ~/.profile
echo 'fi' >> ~/.profile
