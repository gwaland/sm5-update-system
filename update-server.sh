#!/bin/bash
SM_PATH=/home/piu/stepmania
SM_INSTALL_PATH=/home/piu/sm5-install
PIUIO_PATH=/home/piu/piuio
THEME_PATH=/home/piu/Themes/PIU-Delta-GW
#THEME_PATH=/home/piu/Themes
SM_REPO_PATH=/home/piu/repo/sm5
THEME_REPO_PATH=/home/piu/repo/theme
PIUIO_REPO_PATH=/home/piu/repo/piuio
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
   -t      Force a build on the themese directory
   -v      Verbose
   -c      Check only (implies -v)
EOF
}

#parse options. 
BUILD_SM=0
BUILD_PIUIO=0
BUILD_THEME=0
VERBOSE=0
CHECK_ONLY=0
while getopts .hsptvc. OPTION
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
		t)
			BUILD_THEME=1
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
	make clean > /dev/null 2>&1 &
	spinner $!
	log "Configuring Stepmania"
	./autogen.sh
	./configure   --with-static-png   --with-static-jpeg --with-static-zlib  --with-static-bzip  --with-static-vorbis --prefix=$SM_INSTALL_PATH > configure.out 2>&1 &
	spinner $!
	rm -rf $SM_INSTALL_PATH/stepmania\ 5
	log "Making Stepmania!"
	make > make.out 2>&1 &
	spinner $!
	if [ $? -eq 0 ]; then
#		cp src/stepmania ./
#		cp src/GtkModule.so ./
		make install > make.install 2>&1 &
		spinner $!
	        cd $SM_INSTALL_PATH/stepmania\ 5
        	mkdir -p bundle/ffmpeg/libavformat/ > /dev/null
	        mkdir -p bundle/ffmpeg/libavformat/ > /dev/null
        	mkdir -p bundle/ffmpeg/libavutil/ > /dev/null
	        mkdir -p bundle/ffmpeg/libswscale/ > /dev/null
        	mkdir -p bundle/ffmpeg/libavcodec/ > /dev/null
	        cp /home/piu/stepmania/bundle/ffmpeg/libavformat/libavformat.so.55 bundle/ffmpeg/libavformat/
        	cp /home/piu/stepmania/bundle/ffmpeg/libavutil/libavutil.so.52 bundle/ffmpeg/libavutil/
	        cp /home/piu/stepmania/bundle/ffmpeg/libswscale/libswscale.so.2 bundle/ffmpeg/libswscale/
        	cp /home/piu/stepmania/bundle/ffmpeg/libavcodec/libavcodec.so.55 bundle/ffmpeg/libavcodec
	        touch portable.ini
		bundle_sm
	fi
}

#build the release package and md5sum and update -current symlinks
bundle_sm ()
{
	_NOW=$(date +%Y%m%d%H%M)
	cd $SM_INSTALL_PATH/stepmania\ 5
	touch build-$_NOW
	log "Creating stepmania tar bundle."
	tar -czf $SM_REPO_PATH/stepmania-build-$_NOW.tar.gz * 
	ln -sf $SM_REPO_PATH/stepmania-build-$_NOW.tar.gz $SM_REPO_PATH/stepmania-build-current.tar.gz
	log "Creating stepmania md5sum"
	md5sum $SM_REPO_PATH/stepmania-build-$_NOW.tar.gz | awk '{ print $1 }' > $SM_REPO_PATH/stepmania-build-$_NOW.md5sum
	ln -sf $SM_REPO_PATH/stepmania-build-$_NOW.md5sum $SM_REPO_PATH/stepmania-build-current.md5sum
}
bundle_piu_theme ()
{
        _NOW=$(date +%Y%m%d%H%M)
        cd $THEME_PATH 
	git pull > /dev/null
	log "Creating piu theme bundle"
	tar -cazf $THEME_REPO_PATH/piu-delta-theme-$_NOW.tar.gz BANNERS/ Fonts/ BGAnimations/ Graphics/ Languages/ Other/ metrics.ini Scripts/ Sounds/ ThemeInfo.ini
        ln -sf $THEME_REPO_PATH/piu-delta-theme-$_NOW.tar.gz $THEME_REPO_PATH/piu-delta-theme-current.tar.gz
        log "Creating piu theme md5sum"
        md5sum $THEME_REPO_PATH/piu-delta-theme-$_NOW.tar.gz | awk '{ print $1 }' > $THEME_REPO_PATH/piu-delta-theme-$_NOW.md5sum
        ln -sf $THEME_REPO_PATH/piu-delta-theme-$_NOW.md5sum $THEME_REPO_PATH/piu-delta-theme-current.md5sum


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
if [ $BUILD_THEME = 0 ]; then
	STATUS=$(check_git $THEME_PATH 'piu theme') 
	BUILD_THEME=$?
	log $STATUS
else
	log 'Forcing update of theme package'
fi
#Check to see if we are building stepmania
if [ $CHECK_ONLY = 0 ]; then
	if [ $BUILD_SM = 1 ]; then
		build_sm
	fi
	if [ $BUILD_THEME = 1 ]; then
		bundle_piu_theme
	fi
        if [ $BUILD_PIUIO = 1 ]; then
                bundle_piuio
        fi
fi
exit 1

