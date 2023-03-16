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


# check gamescope-session if it needs to be patched
grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session
if [ $? -eq 0 ]
then	echo -e "$RED"gamescope-session needs to be patched!
	sudo steamos-readonly disable
	echo Backup exising gamescope-session.
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session.
	sed 's/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=40,70/g' /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	sudo steamos-readonly enable
else
	echo -e "$GREEN"gamescope-session already patched, no action needed.
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
grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session
if [ \$? -eq 0 ]
then	echo gamescope-session needs to be patched! >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly disable >> \$RefreshRateUnlockerStatus
	echo Backup exising gamescope-session. >> \$RefreshRateUnlockerStatus
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session. >> \$RefreshRateUnlockerStatus
	sed 's/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=40,70/g' /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	ls /bin/gamescope* >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly enable
else
	echo gamescope-session already patched, no action needed. >> \$RefreshRateUnlockerStatus
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
