#!/bin/bash

clear

echo Refresh Rate Unlocker Script by ryanrudolf
echo Discord user dan2wik for the idea on overclocking the display panel to 70Hz
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
echo YT - 10MinuteSteamDeckGamer
sleep 2

# define variables here
steamdeck_model=$(cat /sys/class/dmi/id/board_name | tr '[:upper:]' '[:lower:]')
gamescope_orig=$PWD/gamescope/3.6.20/gamescope-3.6.20-orig
gamescope_unlocked=$PWD/gamescope/3.6.20/gamescope-3.6.20-unlocked
steamos_version=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2)
gamescope_orig_md5sum=c522838a242fabe519958903253a2a4c
gamescope_unlocked_md5sum=641af753637c710f72748d4ec7fb655b
actual_gamescope_orig_md5sum=$(md5sum $PWD/gamescope/3.6.20/gamescope-3.6.20-orig | cut -d " " -f1)
actual_gamescope_unlocked_md5sum=$(md5sum $PWD/gamescope/3.6.20/gamescope-3.6.20-unlocked | cut -d " " -f1)

# sanity check - make sure this is on LCD model
if [ $steamdeck_model = "jupiter" ]
then
	echo Steam Deck LCD detected.
else
	echo Steam Deck OLED detected.
	echo Script only works on Steam Deck LCD model.
	exit
fi

# sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
xdpyinfo &> /dev/null
if [ $? -eq 0 ]
then
	echo Script is running in Desktop Mode.
else
 	echo Script is NOT running in Desktop Mode.
  	echo Please run the script in Desktop Mode as mentioned in the README. Goodbye!
	exit
fi

# sanity check - make sure this is running on SteamOS 3.6.20
if [ $steamos_version = 3.6.20 ]
then
	echo Script is running on supported SteamOS - $steamos_version.
else
	echo SteamOS - $steamos_version detected. This is NOT a supported version of this script!
	echo Make sure the SteamOS version is at 3.6.20 and run the script again.
fi

# sanity check - perform md5sum hash check
if [ $actual_gamescope_orig_md5sum = $gamescope_orig_md5sum ] && \
       	[ $actual_gamescope_unlocked_md5sum = $gamescope_unlocked_md5sum ]
then
	echo Downloaded files contain a valid md5sum hash.
else
	echo Hash mismatch - possible corrupt download. Clone the repo again!
	exit
fi

# sanity check - make sure sudo password is already set
if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	read -s -p "Please enter current sudo password: " current_password ; echo
	echo Checking if the sudo password is correct.
	echo -e "$current_password\n" | sudo -S -k ls &> /dev/null

	if [ $? -eq 0 ]
	then
		echo Sudo password is good!
	else
		echo Sudo password is wrong! Re-run the script and make sure to enter the correct sudo password!
		exit
	fi
else
	echo Sudo password is blank! Setup a sudo password first and then re-run script!
	passwd
	exit
fi

# sanity checks are all good. lets go!
# display warning / disclaimer
zenity --question --title "Steam Deck Refresh Rate Unlocker" --text \
	"WARNING: This is for educational and research purposes only! \
	\n\nThe script has been tested with Steam Deck LCD and the original LCD panel. \
	\nThis may / may not work with and may / may not cause damage to a DeckHD panel. \
	\nIf you use a DeckHD panel then proceed at your own risk! \
	\n\nThe author of this script takes no responsibility for any damage. \
	\n\nDo you agree to the terms and conditions ?" --width 650 --height 75
			if [ $? -eq 1 ]
			then
				echo User pressed NO. Exit immediately.
				exit
			else
				echo User pressed YES. Continue with the script
			fi

###### Main menu. Ask user to UNINSTALL or INSTALL

Choice=$(zenity --width 700 --height 220 --list --radiolist --multiple --title "Refresh Rate Unlocker - https://github.com/ryanrudolfoba/SteamOS-RefreshRateUnlocker"\
	--column "Select One" \
	--column "Refresh Rate Limit" \
	--column="Description - Read this carefully!"\
	FALSE INSTALL "Install the 70Hz mod."\
	FALSE UNINSTALL "Remove the 70Hz mod."\
	TRUE EXIT "Don't make any changes and exit immediately.")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	echo User pressed CANCEL / EXIT. Make no changes. Exiting immediately.
	exit

elif [ "$Choice" == "INSTALL" ]
then
	echo Installing the 70Hz mod.
	echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
	echo -e "$current_password\n" | sudo -S cp $gamescope_unlocked /usr/bin/gamescope
	if [ $? -eq 0 ] && [ $(md5sum /usr/bin/gamescope | cut -d " " -f 1) = $gamescope_unlocked_md5sum ]
	then
		echo 70Hz mod successfully installed.
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		exit
	else
		echo Error installing the 70Hz mod.
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		exit
	fi
	
elif [ "$Choice" == "UNINSTALL" ]
then
	echo Removing the 70Hz mod.
	echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
	echo -e "$current_password\n" | sudo -S cp $gamescope_orig /usr/bin/gamescope
	if [ $? -eq 0 ] && [ $(md5sum /usr/bin/gamescope | cut -d " " -f 1) = $gamescope_orig_md5sum ]
	then
		echo 70Hz mod successfully removed.
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		exit
	else
		echo Error removing the 70Hz mod.
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		exit
	fi
fi
