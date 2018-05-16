#!/bin/sh
#
#written by cl 05.10.2018
#
#v0.2
#
##################################################################################
#exitcodes go here
#exit 3 - Ditto failed
#eixt41 - no dmg on server
##################################################################################

#User Variables Used by Jamf
#desktop Tech username goes here
username="$4"
#Path to User Profile to be restored to; /Users/ is assumed
userHome="/Users/$5"
#Tech Password with access to the server share goes here
passWord="$6"
#Name for the dmg with file extension
dmgFile="$5".dmg
##################################################################################

##################################################################################
#Script variables

#JamfHelper Path - Not used in this version
#jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
#Mount Point for Profile Share
mntPoint=/tmp/profileShare
#Profile backup location - insert the server name and share here eg Server1/profilebaks
profileServer=<insert server name and share here>
#Path to Backup
targetDMG="$mntPoint"/profiles/$dmgFile
#localadmin location to copy the DMG for after moving it locally - Insert the path to the desktop for your 
# local admin account here to move from the temp folder for posterity
TechDesktop=<localadmin/desktoppath>
#migration log file
migLog=/var/log/migration.log
#Restore path
restorePath=/Volumes/$5
##################################################################################
#Functions

#Mount Profile Back up location
mountShr(){
    #Checks to see if Mount Point exsists and is a directory. If it does not exsist it creates the Mountpoint

  if [ -e "$mntPoint" ] && [[ -d "$mntPoint" ]] 
    then :
    else mkdir $mntPoint
fi
    #Mounts the filemigration share on the backup server
    mount -t smbfs "//$username:$passWord@$profileServer" $mntPoint
}

#Clean up after Mounting
cleanUp(){
    #Unmount the Server from the system
    umount $mntPoint
    
    #Checks to see if the mountpoint folder is still there and if so it deletes it
    if [ -d "$mntPoint" ];then
        rm -d "$mntPoint"
    fi
    hdiutil detach /tmp/$dmgFile
}

#Copy DMG from server to local drive

copyDMG(){

    #Checks the mounted server for the dmg file specified by the $dmgFile Variable and if it exsists and is not a 0KB file then it copies it to the tmp folder.
    #The Function copies the file again from tmp to the local admin desktop folder for posterity's sake since tmp is a temp location.
    #tech will need to manually delete this file if the restore is successful
    if [ -e "$targetDMG" ] && [[ -s "$targetDMG" ]];then
        cp "$targetDMG" /tmp
        cp /tmp/$dmgFile $TechDesktop
        echo "$dmgFile copied from $profileServer/profiles to Desktop"
        else echo 'DMG file missing from Server' | exit 41
    fi
}

#Restore back up to Exsisting Profile

restoreProf(){
    if [ -d "$userHome" ]
        then mv $userHome $userHome.old
            if [ -e /tmp/"$dmgFile" ] 
            then hdiutil attach /tmp/$dmgFile
                mkdir $userHome
                ditto $restorePath/ $userHome/ >> $migLog
                if [ $? == 0 ]; then
                    local copycomplete=TRUE
                    else local copycomplete=FALSE
                fi
                else echo "dmg file missing from tmp folder"
            fi
        else echo "User has never logged into the system. Please have the User log in to create a Profile on the Mac"
    
    fi
    if [ "$copycomplete" == TRUE ]; then
   diskUtil resetUserPermissions / `id -u` | echo $?
#Don't think chown is necessary anymore commented out
#chown -R "$5:Domain Users" $userHome | echo "Correcting User permissions" 
        else echo "Copy failed"
    fi
}
#############################################################################################################################
#Executing functions
#Attempting to Mount Server

executeMig(){

mountShr

#Check success of mounted Server and if successful run copyDMG Function
if [ $? == 0 ]; then
    copyDMG
    else echo "Mounting Server failed"

fi

#Check success of copyDMG function and if successful run restoreProf Fuction
if [ $? == 0 ]; then
    restoreProf 
    else echo "dmg copy failed"

fi

cleanUp | echo "Cleaning up after script"
}

executeMig >> $migLog
