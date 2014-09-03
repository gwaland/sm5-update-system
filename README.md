# sm5-update-system

This is a series of scripts for handling updating stepmania on a server to update a pump it up MK6 system when it boots up.  The update-server.sh and build-server are currently relatively stable.   The client side is still being heavily worked on.

## update-server.sh

 - Server side script
 - checks github to see if local stepmania repo is up to date.
	 - If update needed it will update and compile a new copy.
	 - If compilation is successfull a new tar.gz bundle will be created.
	 - New tar bundles are placed in the web directory and labeled -current.
 - checks for new piuio module and bundles it if it exists
 - checks themes directories for updates to themes and packages them for installation if they exist.
 - md5sum is provided to verify current installed version on PIU machine.


## update-client.sh

 -  Script on MK6/MK9 PIU machine
 - grabs new song updates from server
 - rsync new themes, stepmania builds and piuio sources.
 - if new stepmania build exists it installs it. 
 - if new themes exist they're installed. 


## build-server.sh

 - Creates the server side of the update system.  
 - Assumes base ubuntu 14.04 is installed from mini.iso 
 - only packages assumed are git and ssh
 - wizard used to git information needed.

## build-client.sh

 - Creates the client side of the system. 
 - Assumes installation from ubuntu 14.04 from mini.iso
 - only git and ssh assumed to be installed
 - Requires the server to be built first. 
 - Will run update-client.sh on boot before starting stepmania
