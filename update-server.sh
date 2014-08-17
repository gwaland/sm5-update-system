#!/bin/bash
SM_PATH=/home/piu/stepmania
PIUIO_PATH=/home/piu/piuio
PIU_DELTA_PATH=/home/piu/PIU-Delta-GW
WEB_PATH=/var/www/html
#usage display
log()
{
	if [ $VERBOSE = 1 ]; then
		echo "$@"
	fi
}

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
   -c      Check only (implies -v)
EOF
}

#parse options. 
BUILD_SM=0
BUILD_PIUIO=0
BUILD_GW=0
VERBOSE=0
CHECK_ONLY=0
while getopts .hspgvc. OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		v)
                       VERBOSE=1
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
		c)
			VERBOSE=1
			CHECK_ONLY=1
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
	printf "    \b\b\b\b"
}

#basic function to update to the latest get, run make clean and make and if successful build the release package.
build_sm ()
{
	cd $SM_PATH
	log "Updating Repository"
	git pull > /dev/null
	log "Cleaning Stepmania Repo"
	make clean > /dev/null 2>&1
	log "Making Stepmania!"
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
	_NOW=$(date +%Y%m%d%H%M)
	cd $SM_PATH
	log "Creating stepmania tar bundle."
	tar -czf $WEB_PATH/stepmania-build-$_NOW.tar.gz ./Announcers/ ./BackgroundEffects/ ./BackgroundTransitions/ ./BGAnimations/ ./bundle/ ./Characters/ ./Courses/ ./Data/ ./Docs/ ./icons/ ./Manual/ ./NoteSkins/ ./Program/ ./Scripts/ ./Themes/ ./stepmania ./GtkModule.so
	ln -sf $WEB_PATH/stepmania-build-$_NOW.tar.gz $WEB_PATH/stepmania-build-current.tar.gz
	log "Creating stepmania md5sum"
	md5sum $WEB_PATH/stepmania-build-$_NOW.tar.gz > $WEB_PATH/stepmania-build-$_NOW.md5sum
	ln -sf $WEB_PATH/stepmania-build-$_NOW.md5sum $WEB_PATH/stepmania-build-current.md5sum
}
bundle_piu_theme ()
{
        _NOW=$(date +%Y%m%d%H%M)
        cd $PIU_DELTA_PATH 
	git pull > /dev/null
	log "Creating piu theme bundle"
	tar -cazf $WEB_PATH/piu-delta-theme-$_NOW.tar.gz BANNERS/ Fonts/ BGAnimations/ Graphics/ Languages/ Other/ metrics.ini Scripts/ Sounds/ ThemeInfo.ini
        ln -sf $WEB_PATH/piu-delta-theme-$_NOW.tar.gz $WEB_PATH/piu-delta-theme-current.tar.gz
        log "Creating piu theme md5sum"
        md5sum $WEB_PATH/piu-delta-theme-$_NOW.tar.gz > $WEB_PATH/piu-delta-theme-$_NOW.md5sum
        ln -sf $WEB_PATH/piu-delta-theme-$_NOW.md5sum $WEB_PATH/piu-delta-theme-current.md5sum


}

bundle_piuio ()
{
	cd $PIUIO_PATH
	log 'Creating PIUIO bundle'
#still working on this. 
}

#check stepmania to see if it needs to be updated. 
check_git ()
{
	local GIT_CHECK=0
	cd $1
	git fetch
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse @{u})
        BASE=$(git merge-base @ @{u})
        if [ $LOCAL = $REMOTE ]; then
                log "$2 is current."
        elif [ $LOCAL = $BASE ]; then
                log "building $2 bundle"
                GIT_CHECK=1
        elif [ $REMOTE = $BASE ]; then
                log "Local $2 repo manually updated."
        else
                log "Local $2 repo diverged"
        fi
	exit $GIT_CHECK

}

#main functions. 
#check_sm
#check_piuio
#check_theme
if [ $BUILD_PIUIO = 0 ]; then
	STATUS=$(check_git $PIUIO_PATH 'piuio')
	BUILD_PIUIO=$?
	log $STATUS
else
	log 'Forcing update of piuio package'
fi
if [ $BUILD_SM = 0 ]; then
	STATUS=$(check_git $SM_PATH 'stepmania')
	BUILD_SM=$?
	log $STATUS
else
	log 'Forcing update of stepmania package'
fi
if [ $BUILD_GW = 0 ]; then
	STATUS=$(check_git $PIU_DELTA_PATH 'piu delta theme') 
	BUILD_GW=$?
	log $STATUS
else
	log 'Forcing update of theme package'
fi
#Check to see if we are building stepmania
if [ $CHECK_ONLY = 0 ]; then
	if [ $BUILD_SM = 1 ]; then
		build_sm
	fi
	if [ $BUILD_GW = 1 ]; then
		bundle_piu_theme
	fi
        if [ $BUILD_PIUIO = 1 ]; then
                bundle_piuio
        fi
fi
exit 1

