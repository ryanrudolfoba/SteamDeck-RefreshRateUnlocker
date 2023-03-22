#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'

clear

echo Refresh Rate Unlocker Script by ryanrudolf
echo Discord user dan2wik for the idea on overclocking the display panel to 70Hz
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
sleep 2

# Password sanity check - make sure sudo password is already set by end user!

if [ "$(passwd --status deck | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	read -s -p "Please enter current sudo password: " current_password ; echo
	echo Checking if the sudo password is correct.
	echo -e "$current_password\n" | sudo -S -k ls &> /dev/null

	if [ $? -eq 0 ]

	then
		echo -e "$GREEN"Sudo password is good!
	else
		echo -e "$RED"Sudo password is wrong! Re-run the script and make sure to enter the correct sudo password!
		exit
	fi

else
	echo -e "$RED"Sudo password is blank! Setup a sudo password first and then re-run script!
	passwd
	exit
fi

# sudo password is already set by the end user, all good let's go!
echo -e "$current_password\n" | sudo -S ls &> /dev/null
if [ $? -eq 0 ]
then
	echo -e "$GREEN"1st sanity check. So far so good!
else
	echo -e "$RED"Something went wrong on the 1st sanity check! Re-run script!
	exit
fi


###### Main menu. Ask user for the preferred refresh rate limit

Choice=$(zenity --width 1100 --height 300 --list --radiolist --multiple --title "Refresh Rate Unlocker - https://github.com/ryanrudolfoba/SteamOS-RefreshRateUnlocker"\
	--column "Select One" \
	--column "Refresh Rate Limit" \
	--column="Comments - Read this carefully!"\
	FALSE 30,60 "Set the refresh rate limit to 30Hz - 60Hz. Underclock lower limit set to 30Hz and upper limit set to default 60Hz."\
	FALSE 30,70 "Set the refresh rate limit to 30Hz - 70Hz. Underclock lower limit to 30Hz and overclock upper limit to 70Hz."\
	FALSE 40,70 "Set the refresh rate limit to 40Hz - 70Hz. Lower limit set to default 40Hz and overclock upper limit to 70Hz"\
	TRUE EXIT "Select this if you changed your mind and don't want to proceed anymore.")

#[[ $? = 0 ]] || echo User pressed CANCEL. Exit immdediately. ; exit 

if [ $? -eq 1 ]
then
	echo User pressed CANCEL. Make no changes. Exiting immediately.
	exit

elif [ "$Choice" == "EXIT" ]
then
	echo User selected EXIT. Make no changes. Exiting immediately.
	exit

else
	# check gamescope-session if it needs to be patched
	grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session
	if [ $? -eq 0 ]
	then	echo -e "$RED"gamescope-session needs to be patched!
		sudo steamos-readonly disable
		echo Backup existing gamescope-session.
		sudo cp /bin/gamescope-session /bin/gamescope-session.backup
		echo Patch the gamescope-session.
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
		sudo cp /bin/gamescope-session.patched /bin/gamescope-session
		sudo steamos-readonly enable
	else
		echo -e "$GREEN"gamescope-session already patched, no action needed.
	fi
fi
#################################################################################
################################ post install ###################################
#################################################################################

# create ~/1RefreshRateUnlocker and place the scripts in there
mkdir ~/1RefreshRateUnlocker &> /dev/null
rm ~/1RefreshRateUnlocker/* &> /dev/null

# uninstall-RefreshRateUnlocker.sh
cat > ~/1RefreshRateUnlocker/uninstall-RefreshRateUnlocker.sh << EOF
#!/bin/bash

# restore gamescope-session from backup
sudo steamos-readonly disable
sudo mv /bin/gamescope-session.backup /bin/gamescope-session
sudo rm /bin/gamescope-session.patched
sudo steamos-readonly enable

rm -rf ~/1RefreshRateUnlocker/*

grep -v 1RefreshRateUnlocker ~/.bash_profile > ~/.bash_profile.temp
mv ~/.bash_profile.temp ~/.bash_profile

echo Uninstall complete. Reboot Steam Deck for changes to take effect.

EOF

# post-install-RefreshRateUnlocker.sh
cat > ~/1RefreshRateUnlocker/post-install-RefreshRateUnlocker.sh << EOF
#!/bin/bash

RefreshRateUnlockerStatus=~/1RefreshRateUnlocker/status.txt

echo -e "$current_password\n" | sudo -S ls &> /dev/null


echo RefreshRateUnlocker > \$RefreshRateUnlockerStatus
date >> \$RefreshRateUnlockerStatus
cat /etc/os-release >> \$RefreshRateUnlockerStatus


# check gamescope file if it needs to be patched
grep STEAM_DISPLAY_REFRESH_LIMITS=$Choice /bin/gamescope-session
if [ \$? -eq 0 ]
then	echo gamescope-session already patched, no action needed. >> \$RefreshRateUnlockerStatus
else
	echo gamescope-session needs to be patched! >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly disable >> \$RefreshRateUnlockerStatus
	echo Backup exising gamescope-session. >> \$RefreshRateUnlockerStatus
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session. >> \$RefreshRateUnlockerStatus
	sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	ls /bin/gamescope* >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly enable
fi

EOF

grep 1RefreshRateUnlocker ~/.bash_profile &> /dev/null
if [ $? -eq 0 ]
then
	echo -e "$GREEN"RefreshRateUnlocker script already present no action needed! RefreshRateUnlocker install is done!
else
	echo -e "$RED"Post install script not found! Adding post install script!
	echo "~/1RefreshRateUnlocker/post-install-RefreshRateUnlocker.sh" >> ~/.bash_profile
	echo -e "$GREEN"Post install script added! RefreshRateUnlocker install is done!
fi

chmod +x ~/1RefreshRateUnlocker/*
