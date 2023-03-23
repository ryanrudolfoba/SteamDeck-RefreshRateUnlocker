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

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	echo User pressed CANCEL / EXIT. Make no changes. Exiting immediately.
	exit

else
	sudo steamos-readonly disable
	echo Perform cleanup first.
	sudo rm /bin/gamescope-session.patched /bin/gamescope-session.backup &> /dev/null
	echo Backup existing gamescope-session.
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session.
	
	# check the possible combinations and then patch gamescope-session based on the user choice
	grep STEAM_DISPLAY_REFRESH_LIMITS=30,60 /bin/gamescope-session
	if [ $? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=30,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi

	grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session
	if [ $? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi

	grep STEAM_DISPLAY_REFRESH_LIMITS=30,70 /bin/gamescope-session
	if [ $? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=30,70/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi

	grep STEAM_DISPLAY_REFRESH_LIMITS=40,70 /bin/gamescope-session
	if [ $? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,70/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi
	
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	sudo steamos-readonly enable
	grep STEAM_DISPLAY_REFRESH_LIMITS /bin/gamescope-session
	echo -e "$GREEN"gamescope-session has been patched to use $Choice. Reboot Steam Deck for changes to take effect.
fi

#################################################################################
################################ post install ###################################
#################################################################################

# create ~/1RefreshRateUnlocker and place the additional scripts in there
mkdir ~/1RefreshRateUnlocker &> /dev/null
rm -f ~/1RefreshRateUnlocker/* &> /dev/null

# uninstall-RefreshRateUnlocker.sh - use this to uninstall
cat > ~/1RefreshRateUnlocker/uninstall-RefreshRateUnlocker.sh << EOF
#!/bin/bash

# restore gamescope-session from backup
sudo steamos-readonly disable
sudo mv /bin/gamescope-session.backup /bin/gamescope-session

# verify that gamescope-session is now using the default 40,60
grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session > /dev/null
if [ \$? -ne 0 ]
then	echo gamescope-session needs to be patched back to the default values.
	echo Patch the gamescope-session to the default values.
	
	# check the possible combinations and then patch gamescope-session based on the user choice
	grep STEAM_DISPLAY_REFRESH_LIMITS=30,60 /bin/gamescope-session
	if [ \$? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=30,60/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi

	grep STEAM_DISPLAY_REFRESH_LIMITS=30,70 /bin/gamescope-session
	if [ \$? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=30,70/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi

	grep STEAM_DISPLAY_REFRESH_LIMITS=40,70 /bin/gamescope-session
	if [ \$? -eq 0 ]
	then
		sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,70/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	fi
	
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	echo gamescope-session is now using the default value 40,60.
else
	echo gamescope-session is now using the default value 40,60.
fi

sudo rm /bin/gamescope-session.patched

# delete systemd service
sudo systemctl stop refresh-rate-unlocker.service
sudo rm /etc/systemd/system/refresh-rate-unlocker.service
sudo systemctl daemon-reload
sudo steamos-readonly enable

rm -rf ~/1RefreshRateUnlocker/*

echo Uninstall complete. Reboot Steam Deck for changes to take effect.

EOF

# post-install-RefreshRateUnlocker.sh - this checks every startup if the patch needs to be reapplied
cat > ~/1RefreshRateUnlocker/post-install-RefreshRateUnlocker.sh << EOF
#!/bin/bash

RefreshRateUnlockerStatus=/home/deck/1RefreshRateUnlocker/status.txt

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
	echo Backup existing gamescope-session. >> \$RefreshRateUnlockerStatus
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session. >> \$RefreshRateUnlockerStatus
	sed "s/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session | sudo tee /bin/gamescope-session.patched > /dev/null
	sudo cp /bin/gamescope-session.patched /bin/gamescope-session
	ls /bin/gamescope* >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly enable
fi

EOF

# refresh-rate-unlocker.service - systemd service that calls post-install-RefreshRateUnlocker.sh on startup
cat > ~/1RefreshRateUnlocker/refresh-rate-unlocker.service << EOF

[Unit]
Description=Check if /bin/gamescope-session needs to be patched to unlock refresh rates outside the default 40-60Hz

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '/home/deck/1RefreshRateUnlocker/post-install-RefreshRateUnlocker.sh'

[Install]
WantedBy=multi-user.target

EOF

# check-service-status.sh - check if the refresh-rate-unlocker service is running
cat > ~/1RefreshRateUnlocker/check-service-status.sh << EOF
#!/bin/bash

systemctl status refresh-rate-unlocker | grep "active (exited)" > /dev/null
if [ \$? -ne 0 ]
then
	zenity --width 500 --height 100 --warning --title "Refresh Rate Unlocker Service Status" \\
	--text="Refresh Rate Unlocker Service is not running! \\nRe-run the ~/1RefreshRateUnlocker/reinstall-service.sh script!"

else

	zenity --width 500 --height 100 --warning --title "Refresh Rate Unlocker Service Status" --text="Refresh Rate Unlocker Service is running! No further action needed."
fi

EOF

# reinstall-service.sh - reinstall the refresh-rate-unlocker.service
cat > ~/1RefreshRateUnlocker/reinstall-service.sh << EOF
sudo steamos-readonly disable
sudo cp ~/1RefreshRateUnlocker/refresh-rate-unlocker.service /etc/systemd/system/refresh-rate-unlocker.service
sudo systemctl daemon-reload
sudo systemctl enable refresh-rate-unlocker.service
sudo steamos-readonly enable

echo Refresh Rate Unlocker service has been reinstalled. Reboot Steam Deck for changes to take effect.
EOF

chmod +x ~/1RefreshRateUnlocker/*.sh
sudo cp ~/1RefreshRateUnlocker/refresh-rate-unlocker.service /etc/systemd/system/refresh-rate-unlocker.service
sudo systemctl daemon-reload
sudo systemctl enable --now refresh-rate-unlocker.service
