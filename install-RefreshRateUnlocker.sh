#!/bin/bash

clear

echo Steam Deck Refresh Rate Unlocker / 70Hz LCD mod script  by ryanrudolf
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
echo YT - 10MinuteSteamDeckGamer
sleep 2

# capture SteamOS version and Steam Deck model
MODEL=$(cat /sys/class/dmi/id/board_name)
STEAMOS_VERSION=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2 | cut -d "." -f1-2 )
STEAMOS_VERSION_FULL=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2)
BASE_VERSION=3.5
MAX_VERSION=3.8

# SteamOS 3.7 and above unlock method using custom LUA
LCD_TEMPLATE=/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua
SCRIPT_LOCATION=$HOME/.config/gamescope/scripts
SCRIPT_NAME=valve.steamdeck.lcd.70Hz.lua

# SteamOS 3.6.20 unlock method using patched gamescope
# GS=GAMESCOPE
GS_ORIG=$PWD/gamescope/3.6.20/gamescope-3.6.20-orig
GS_PATCHED=$PWD/gamescope/3.6.20/gamescope-3.6.20-patched
GS_ORIG_MD5SUM=c522838a242fabe519958903253a2a4c
GS_PATCHED_MD5SUM=641af753637c710f72748d4ec7fb655b
ACTUAL_GS_ORIG_MD5SUM=$(md5sum $PWD/gamescope/3.6.20/gamescope-3.6.20-orig | cut -d " " -f1)
ACTUAL_GS_PATCHED_MD5SUM=$(md5sum $PWD/gamescope/3.6.20/gamescope-3.6.20-patched | cut -d " " -f1)

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

# sanity checks - make sure this is on Valve Steam Deck LCD and running on supported SteamOS version.
if ( awk "BEGIN {exit ! ($STEAMOS_VERSION >= $BASE_VERSION && $STEAMOS_VERSION <= $MAX_VERSION)}" || [ $STEAMOS_VERSION_FULL == "3.6.20" ] ) && [ "$MODEL" == "Jupiter" ]
then
	echo Test 1. SteamOS $STEAMOS_VERSION_FULL detected. Proceed to the next step.
else
	echo SteamOS $STEAMOS_VERSION_FULL detected. This is unsupported version.
	exit
fi

# sanity checks are all good. lets go!
# display warning / disclaimer
zenity --question --title "Steam Deck Refresh Rate Unlocker" --text \
	"WARNING: This is for educational and research purposes only! \
	\n\nThe script has been tested with Steam Deck LCD and the original LCD panel. \
	\nThis may / may not work with and may / may not cause damage to a DeckHD / DeckSight panel. \
	\n\nIf you use a DeckHD / DeckSight panel then proceed at your own risk! \
	\n\nThe author of this script takes no responsibility for any damage. \
	\n\nDo you agree to the terms and conditions ?" --width 700 --height 75
			if [ $? -eq 1 ]
			then
				echo User DOES NOT agree with the terms and conditions. Exit immediately.
				exit
			else
				echo User agrees to the terms and conditions. Continue with the script.
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
	# check if LUA method
	if awk "BEGIN {exit ! ($STEAMOS_VERSION >= 3.7 && $STEAMOS_VERSION <= $MAX_VERSION)}" && [ "$MODEL" == "Jupiter" ]
	then
		echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		# create gamescope user script directory
		if [ -d $SCRIPT_LOCATION ]
		then
			echo The location $SCRIPT_LOCATION already exists.
		else
			echo The location $SCRIPT_LOCATION does not exist. Creating it now.
			mkdir -p $SCRIPT_LOCATION
		fi

		# copy the existing gamescope template to the gamescope user script directory
		if [ -e $LCD_TEMPLATE ]
		then
			echo Copying 70Hz LCD mod.
			cp $LCD_TEMPLATE $SCRIPT_LOCATION/$SCRIPT_NAME
		else
			echo Default Gamescope template not found!
			echo Please open an issue report on my GitHub repo or leave a comment on the YT channel - 10MinuteSteamDeckGamer.
			exit
		fi

		# make the changes via sed string manipulation
		echo Activating 70Hz LCD mod.
		sed -i '/50, 51, 52, 53, 54, 55, 56, 57, 58, 59,/!b;n;c\\t60, 61, 62, 63, 64, 65, 66, 67, 68, 69, \n\t70' $SCRIPT_LOCATION/$SCRIPT_NAME
		
		if [ $? -eq 0 ]
		then
			echo 70Hz LCD mod successfully installed.
			echo Returning to Game Mode in 5sec.
			sleep 5
			qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
		else
			echo 70Hz LCD mod NOT successfully installed.
			echo Please open an issue report on my GitHub repo or leave a comment on the YT channel - 10MinuteSteamDeckGamer.
		fi

	# check if gamescope patched method
	elif [ "$STEAMOS_VERSION_FULL" == "3.6.20" ] && [ "$MODEL" == "Jupiter" ]
	then
		# sanity check - perform md5sum hash check
		if [ $ACTUAL_GS_ORIG_MD5SUM = $GS_ORIG_MD5SUM ] && [ $ACTUAL_GS_PATCHED_MD5SUM = $GS_PATCHED_MD5SUM ]
		then
			echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
			echo Downloaded files contain a valid md5sum hash.
			echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
			echo -e "$current_password\n" | sudo -S cp $GS_PATCHED /usr/bin/gamescope
			if [ $? -eq 0 ] && [ $(md5sum /usr/bin/gamescope | cut -d " " -f 1) = $GS_PATCHED_MD5SUM ]
			then
				echo 70Hz mod successfully installed.
				echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
				echo Returning to Game Mode in 5sec.
				sleep 5
				qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
			else
				echo Error installing the 70Hz mod.
				echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
				exit
			fi
		else
			echo Hash mismatch - possible corrupt download. Clone the repo again!
			exit
		fi
	
	# check if gamescope-session method
	elif [ "$STEAMOS_VERSION" == "3.5" ] && [ "$MODEL" == "Jupiter" ]
	then
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		sed 's/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=40,70/g' /bin/gamescope-session | sudo tee /bin/gamescope-session &> /dev/null
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		echo 70Hz mod successfully installed.
		echo Returning to Game Mode in 5sec.
		sleep 5
		qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
	fi

elif [ "$Choice" == "UNINSTALL" ]
then
	if awk "BEGIN {exit ! ($STEAMOS_VERSION >= 3.7 && $STEAMOS_VERSION <= $MAX_VERSION)}" && [ "$MODEL" == "Jupiter" ]
	then
		echo Removing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		rm $SCRIPT_LOCATION/$SCRIPT_NAME
		echo 70Hz mod successfully removed.
		exit

	elif [ "$STEAMOS_VERSION_FULL" == "3.6.20" ] && [ "$MODEL" == "Jupiter" ]
	then
		echo Removing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo -e "$current_password\n" | sudo -S cp $GS_ORIG /usr/bin/gamescope
		if [ $? -eq 0 ] && [ $(md5sum /usr/bin/gamescope | cut -d " " -f 1) = $GS_ORIG_MD5SUM ]
		then
			echo 70Hz mod successfully removed.
			echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
			exit
		else
			echo Error removing the 70Hz mod.
			echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
			exit
		fi
	
	elif [ "$STEAMOS_VERSION" == "3.5" ] && [ "$MODEL" == "Jupiter" ]
	then
		echo Removing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION.
		sed 's/STEAM_DISPLAY_REFRESH_LIMITS=40,70/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g' /bin/gamescope-session | sudo tee /bin/gamescope-session &> /dev/null
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		echo 70Hz mod successfully removed.
		exit
	fi
fi

