#!/bin/bash
SM_PATH=/home/piu/stepmania
PIUIO_PATH=/hom/piu/piuio
WEB_PATH=/var/www/html
#usage display
usage()
{
cat << EOF
usage: $0 options

This script will check for updates in stepmania, piuio, and the piu-dex-gw skins and build packages if they exist..

OPTIONS:
   -h      Show this message
   -s      Force a build of stepmania 
   -p      Force a build for piuio
   -g      Force a build on the piu-nex-gw
   -v      Verbose
EOF
}

#parse options. 
BUILD_SM=0
BUILD_PIUIO=0
BUILD_GW=0
VERBOSE=0
while getopts .hspgv. OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
             BUILD_SM=1
             ;;
         p)
             BUILD_PIUIO=1 
             ;;
         g)
             BUILD_GW=1
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

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
	if [ $VERBOSE = 1]; then 
		printf "    \b\b\b\b"
	fi
}

#basic function to update to the latest get, run make clean and make and if successful build the release package.
build_sm ()
{
	cd $SM_PATH
	git pull > /dev/null
	make clean > /dev/null 2>&1
	make > make.out 2>&1 &
	spinner $!
	if [ $? -eq 0 ]; then
		cp src/stepmania ./
		cp src/GtkModule.so ./
		bundle_sm
	fi
}

#build the release package and md5sum and update -current symlinks
bundle_sm ()
{
	_NOW=$(date +%Y%m%d%k%M)
	cd $SM_PATH
	tar -czf $WEB_PATH/stepmania-build-$_NOW.tar.gz ./Announcers/ ./BackgroundEffects/ ./BackgroundTransitions/ ./BGAnimations/ ./bundle/ ./Characters/ ./Courses/ ./Data/ ./Docs/ ./icons/ ./Manual/ ./NoteSkins/ ./Program/ ./Scripts/ ./Themes/ ./stepmania ./GtkModule.so
	ln -sf $WEB_PATH/stepmania-build-$_NOW.tar.gz $WEB_PATH/stepmania-build-current.tar.gz
	md5sum $WEB_PATH/stepmania-build-$_NOW.tar.gz > $WEB_PATH/stepmania-build-$_NOW.md5sum
	ln -sf $WEB_PATH/stepmania-build-$_NOW.md5sum $WEB_PATH/stepmania-build-current.md5sum
}

#check stepmania to see if it needs to be updated. 
check_sm ()
{
	cd $SM_PATH
	LOCAL=$(git rev-parse @)
	REMOTE=$(git rev-parse @{u})
	BASE=$(git merge-base @ @{u})
	if [ $LOCAL = $REMOTE ]; then
		echo "stepmania build is current."
	elif [ $LOCAL = $BASE ]; then
		echo "Buidling stepmania"
		BUILD_SM=1
	elif [ $REMOTE = $BASE ]; then
		echo "local repo manually updated."
	else
		echo "Diverged"
	fi
}

#main functions. 
check_sm

#Check to see if we're building stepmania
if [ $BUILD_SM = 1 ]; then
	build_sm
fi
exit 1

