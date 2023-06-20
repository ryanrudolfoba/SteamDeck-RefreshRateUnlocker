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

Choice=$(zenity --width 700 --height 300 --list --radiolist --multiple --title "Refresh Rate Unlocker - https://github.com/ryanrudolfoba/SteamOS-RefreshRateUnlocker"\
	--column "Select One" \
	--column "Refresh Rate Limit" \
	--column="Description - Read this carefully!"\
	FALSE 20,60 "Set the refresh rate limit to 20Hz - 60Hz."\
	FALSE 30,60 "Set the refresh rate limit to 30Hz - 60Hz."\
	FALSE 20,70 "Set the refresh rate limit to 20Hz - 70Hz."\
	FALSE 30,70 "Set the refresh rate limit to 30Hz - 70Hz."\
	FALSE 40,70 "Set the refresh rate limit to 40Hz - 70Hz."\
	TRUE EXIT "Don't make any changes and exit immediately.")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	echo User pressed CANCEL / EXIT. Make no changes. Exiting immediately.
	exit
else
	sudo steamos-readonly disable
	echo Perform cleanup first.
	sudo rm /bin/gamescope-session.backup &> /dev/null
	echo Backup existing gamescope-session.
	sudo cp /bin/gamescope-session /bin/gamescope-session.backup
	echo Patch the gamescope-session.
	
	# patch gamescope-session based on the user choice
	sudo sed -i "s/STEAM_DISPLAY_REFRESH_LIMITS=..,../STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session
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

# RefreshRateUnlocker.sh - script that gets called by refresh-rate-unlocker.service on startup
cat > ~/1RefreshRateUnlocker/RefreshRateUnlocker.sh << EOF
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
	sudo sed -i "s/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=$Choice/g" /bin/gamescope-session
	ls /bin/gamescope* >> \$RefreshRateUnlockerStatus
	sudo steamos-readonly enable
fi
EOF

# refresh-rate-unlocker.service - systemd service that calls RefreshRateUnlocker.sh on startup
cat > ~/1RefreshRateUnlocker/refresh-rate-unlocker.service << EOF

[Unit]
Description=Custom systemd service that unlocks custom refresh rates.

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '/etc/systemd/system/RefreshRateUnlocker.sh'

[Install]
WantedBy=multi-user.target
EOF

################################################################################
####################### Refresh Rate Unlocker Toolbox ##########################
################################################################################
cat > ~/1RefreshRateUnlocker/RefreshRateUnlocker-Toolbox.sh << EOF
#!/bin/bash
zenity --password --title "Password Authentication" | sudo -S ls &> /dev/null
if [ \$? -ne 0 ]
then
	echo sudo password is wrong! | \\
		zenity --text-info --title "Clover Toolbox" --width 400 --height 200
	exit
fi

while true
do
Choice=\$(zenity --width 750 --height 350 --list --radiolist --multiple \
	--title "Refresh Rate Unlocker  Toolbox - https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker"\\
	--column "Select One" \\
	--column "Option" \\
	--column="Description - Read this carefully!"\\
	FALSE Status "Choose this to check the status of the service!"\\
	FALSE 20,60 "Set the refresh rate limit to 20Hz - 60Hz."\
	FALSE 30,60 "Set the refresh rate limit to 30Hz - 60Hz."\
	FALSE 20,70 "Set the refresh rate limit to 20Hz - 70Hz."\
	FALSE 30,70 "Set the refresh rate limit to 30Hz - 70Hz."\
	FALSE 40,70 "Set the refresh rate limit to 40Hz - 70Hz."\
	FALSE Uninstall "Choose this to uninstall and revert any changes made."\\
	TRUE EXIT "***** Exit the Clover Toolbox *****")

if [ \$? -eq 1 ] || [ "\$Choice" == "EXIT" ]
then
	echo User pressed CANCEL / EXIT.
	exit

elif [ "\$Choice" == "Status" ]
then
	zenity --warning --title "Refresh Rate Unlocker Toolbox" --text "\$(fold -w 120 -s ~/1RefreshRateUnlocker/status.txt)" --width 400 --height 600

elif [ "\$Choice" == "20,60" ] || [ "\$Choice" == "30,60" ] || [ "\$Choice" == "20,70" ] || [ "\$Choice" == "30,70" ] || [ "\$Choice" == "40,70" ]
then
	sudo steamos-readonly disable
	sudo sed -i "s/STEAM_DISPLAY_REFRESH_LIMITS=..,../STEAM_DISPLAY_REFRESH_LIMITS=\$Choice/g" /bin/gamescope-session
	sudo steamos-readonly enable
	grep STEAM_DISPLAY_REFRESH_LIMITS /bin/gamescope-session
	zenity --warning --title "Refresh Rate Unlocker Toolbox" \\
	--text "Refresh rate is now set to \$Choice. \nReboot for changes to take effect!" --width 400 --height 75

elif [ "\$Choice" == "Uninstall" ]
then
	# restore gamescope-session from backup if it exists
	sudo steamos-readonly disable
	sudo mv /bin/gamescope-session.backup /bin/gamescope-session

	# verify that gamescope-session is now using the default 40,60
	grep STEAM_DISPLAY_REFRESH_LIMITS=40,60 /bin/gamescope-session > /dev/null
	if [ \$? -ne 0 ]
	then	
		sudo sed -i "s/STEAM_DISPLAY_REFRESH_LIMITS=..,../STEAM_DISPLAY_REFRESH_LIMITS=40,60/g" /bin/gamescope-session
		echo gamescope-session is now using the default value 40,60.
	fi

	# delete systemd service
	sudo systemctl stop refresh-rate-unlocker.service
	sudo rm /etc/systemd/system/refresh-rate-unlocker.service
 	sudo rm /etc/systemd/system/RefreshRateUnlocker.sh
	sudo systemctl daemon-reload
	sudo steamos-readonly enable

	rm -rf ~/1RefreshRateUnlocker
	rm -rf ~/SteamDeck-RefreshRateUnlocker
	rm ~/Desktop/RefreshRateUnlocker-Toolbox

	zenity --warning --title "Refresh Rate Unlocker Toolbox" --text "Uninstall complete! Reboot for changes to take effect!" --width 400 --height 75
	exit
fi
done
EOF

################################################################################
######################### continue with the install ############################
################################################################################
# copy the systemd script to a location owned by root to prevent local privilege escalation
sudo steamos-readonly disable
chmod +x ~/1RefreshRateUnlocker/*.sh
sudo mv ~/1RefreshRateUnlocker/refresh-rate-unlocker.service /etc/systemd/system/refresh-rate-unlocker.service
sudo mv ~/1RefreshRateUnlocker/RefreshRateUnlocker.sh /etc/systemd/system/RefreshRateUnlocker.sh

# start the service
sudo systemctl daemon-reload
sudo systemctl enable --now refresh-rate-unlocker.service
sudo steamos-readonly enable

# create desktop icon for Refresh Rate Unlocker Toolbox
ln -s ~/1RefreshRateUnlocker/RefreshRateUnlocker-Toolbox.sh ~/Desktop/RefreshRateUnlocker-Toolbox
echo -e "$RED"Desktop icon for Refresh Rate Unlocker Toolbox has been created!
