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
if [[ "$STEAMOS_VERSION" == *"$SUPPORTED_VERSION"* ]] && [ $MODEL = "Jupiter" ]

then
	echo Script is running on $MODEL Steam Deck LCD using SteamOS $STEAMOS_VERSION.
	echo This is a supported version / configuration - Steam Deck $MODEL and SteamOS $STEAMOS_VERSION.
else
	echo Script is running on $MODEL Steam Deck LCD using SteamOS $STEAMOS_VERSION.
	echo This is a NOT a supported version / configuration.
	echo Script works on Jupiter Steam Deck LCD and SteamOS 3.7.x.
	exit
fi

# create gamescope user script directory
if [ -d $SCRIPT_LOCATION ]
then
	echo The location $SCRIPT_LOCATION already exists.
	echo Copying 70Hz LCD mod.
else
	echo The location $SCRIPT_LOCATION does not exist. Creating it now.
	mkdir -p $HOME/.config/gamescope/scripts
	echo Copying 70Hz LCD mod.
fi


# copy the existing gamescope template file to the gamescope user script directory
cp /usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua $SCRIPT_LOCATION/$SCRIPT_NAME

# make the changes via sed string manipulation
sed -i '/50, 51, 52, 53, 54, 55, 56, 57, 58, 59,/!b;n;c\\t60, 61, 62, 63, 64, 65, 66, 67, 68, 69, \n\t70' $HOME/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua

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
