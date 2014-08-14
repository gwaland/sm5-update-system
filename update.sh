#!/bin/bash
SM_PATH=/home/piu/stepmania
PIUIO_PATH=/hom/piu/piuio
WEB_PATH=/var/www/html
#spinner class (probably needs to be taken out or a -q -v option added to enable it. 
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

#basic function to update to the latest get, run make clean and make and if successful build the release package.
build_sm ()
{
	cd $SM_PATH
	git pull
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
echo $_NOW
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
		build_sm
		exit 0
	elif [ $LOCAL = $BASE ]; then
		echo "Buidling stepmania"
		build_sm
		exit 0
	elif [ $REMOTE = $BASE ]; then
		echo "local repo manually updated."
		exit 1
	else
		echo "Diverged"
		exit 1
	fi
}

check_sm
