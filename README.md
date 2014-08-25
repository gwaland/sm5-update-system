# sm5-update-system

This is a series of scripts for handling updating stepmania on a server to update a pump it up MK6 system. 

## update-server.sh&nbsp;
<div>

*   <span style="line-height: 19.5px;">Server side script</span>
*   <span style="line-height: 19.5px;">checks github to see if local stepmania repo is up to date.&nbsp;</span>
*   <span style="line-height: 19.5px;">If update needed it will update and compile a new copy.&nbsp;</span>
*   <span style="line-height: 19.5px;">If compilation is successfull a new tar.gz bundle will be created.</span>
*   <span style="line-height: 19.5px;">New tar bundles are placed in the web directory and labeled -current.</span>
*   <span style="line-height: 19.5px;">md5sum is provided to verify current installed version on PIU machine.</span><div>
</div></div>

## update-client.sh
<div>

* script on client to check for updates. &nbsp;Will grab current md5sum file and compare it to installed md5sum file.
* If md5sums do not match new bundle will be downloaded and installed.
* If installation fails, this script will enable a backup copy to start.
* rsync will be run on the Songs directory on the server to grab any new songs or updates from the server.
<div></div></div>

## build-client.sh
<div>

* Builds the infrastructure for the client.  Requires minimal ubuntu install with git, and ssh installed. 
* be sure to edit _SERVER with proper location
* Build the server before installing the client
 
</div>
