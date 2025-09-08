#!/bin/bash

clear

echo Steam Deck Refresh Rate Unlocker / 70Hz LCD mod script  by ryanrudolf
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
echo YT - 10MinuteSteamDeckGamer
sleep 2

# define variables here to capture SteamOS version and Steam Deck model
MODEL=$(cat /sys/class/dmi/id/board_name)
STEAMOS_VERSION=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2)
SUPPORTED_VERSION=3.7.
LCD_TEMPLATE=/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua
SCRIPT_LOCATION=$HOME/.config/gamescope/scripts
SCRIPT_NAME=valve.steamdeck.lcd.70Hz.lua

# sanity checks - make sure this is on Valve Steam Deck LCD and running on supported SteamOS version.
if [[ "$STEAMOS_VERSION" == "$SUPPORTED_VERSION"* ]] && [ "$MODEL" == "Jupiter" ]
then
	echo Script is running on $MODEL Steam Deck LCD using SteamOS $STEAMOS_VERSION.
	echo This is a supported version / configuration - Steam Deck $MODEL and SteamOS $STEAMOS_VERSION.
else
	echo Script is running on $MODEL Steam Deck LCD using SteamOS $STEAMOS_VERSION.
	echo This is a NOT a supported version / configuration.
	echo Script works on Jupiter Steam Deck LCD and SteamOS 3.7.x.
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
