#!/bin/sh
#
#written by cl 05.09.2018
#chris.lamb@childrens.com
#v0.2
#
##################################################################################

#User Variables Used by Jamf
#Username of Tech or Service account with access to the share
username="$4"
#Password of Tech or Service account with access to the Server Share
passWord="$7"
#Path to User Profile to be backed up /Users/ is assumed
userHome="/Users/$5"
#Name for the dmg without file extension
dmgFile="$5"
##################################################################################

#Script variables
#diskUtiliy='/usr/sbin/diskutil'
#Mount Point for Profile Share
mntPoint=/tmp/profileShare
#Profile backup location eg. Servername/share
profileServer=<insert Server Location here>
#dmgActual is full filepath of dmg created by the backupDMG function


##################################################################################

#Functions
backupDMG(){
    hdiutil create -fs HFS+ -srcfolder "$userHome" -volname "$dmgFile" "/tmp/$dmgFile.dmg"
    dmgActual="/tmp/$dmgFile.dmg"
}
mountShr(){
  if [ -e "$mntPoint" ] && [[ -d "$mntPoint" ]] 
    then :
    else mkdir $mntPoint
    fi
    mount -t smbfs "//$username:$passWord@$profileServer" $mntPoint
}
cleanUp(){
    umount $mntPoint
    if [ -d "$mntPoint" ];then
        rm -d "$mntPoint"
    fi
}
copyDMG(){
    if [ -e "$dmgActual" ] && [[ -s "$dmgActual" ]];then
        cp "$dmgActual" "$mntPoint/profiles"
        echo "$dmgFile copied to $profileServer/profiles"
        else echo 'DMG file failed to create'
    fi
}
#####################################################################################
#Running functions
#Creates the dmg backup of the User Folder
backupDMG
#Mounts the share for the back to copy to
mountShr
#Copies the dmg to the server
copyDMG

#echo "Backup of User Home Folder Complete. Please see $profileServer/$dmgfile.dmg for your successfully backed up profile."
#Clean up
cleanUp
echo 'Removing files created by functions'
