# SteamDeck Refresh Rate Unlocker
This repository contains the instructions and scripts on how to unlock the Steam Deck under SteamOS to use upto 70Hz refresh rate for the display (do not confuse this with FPS). \
Discord user dan2wik for the idea on overclocking the display panel to 70Hz!

> **NOTE**\
> If you are going to use this script for a video tutorial, PLEASE reference on your video where you got the script! This will make the support process easier!
> And don't forget to give a shoutout to [@10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/) / ryanrudolf from the Philippines!
>

<b> If you like my work please show support by subscribing to my [YouTube channel @10MinuteSteamDeckGamer.](https://www.youtube.com/@10MinuteSteamDeckGamer/) </b> <br>
<b> I'm just passionate about Linux, Windows, how stuff works, and playing retro and modern video games on my Steam Deck! </b>
<p align="center">
<a href="https://www.youtube.com/@10MinuteSteamDeckGamer/"> <img src="https://github.com/ryanrudolfoba/SteamDeck-Clover-dualboot/blob/main/10minute.png"/> </a>
</p>

<b>Monetary donations are also encouraged if you find this project helpful. Your donation inspires me to continue research on the Steam Deck! Clover script, 70Hz mod, SteamOS microSD, Secure Boot, etc.</b>

<b>Scan the QR code or click the image below to visit my donation page.</b>

<p align="center">
<a href="https://www.paypal.com/donate/?business=VSMP49KYGADT4&no_recurring=0&item_name=Your+donation+inspires+me+to+continue+research+on+the+Steam+Deck%21%0AClover+script%2C+70Hz+mod%2C+SteamOS+microSD%2C+Secure+Boot%2C+etc.%0A%0A&currency_code=CAD"> <img src="https://github.com/ryanrudolfoba/SteamDeck-Clover-dualboot/blob/main/QRCode.png"/> </a>
</p>

## Disclaimer
1. Do this at your own risk!
2. This is for educational and research purposes only!

## Video Tutorial
**[If you prefer a video tutorial then click here.](https://youtu.be/6loG-BXmeQA)**

<p align="center">
<a href="https://youtu.be/6loG-BXmeQA"> <img src="https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/blob/main/video.png"/> </a>
</p>


## Screenshot - Warning / Disclaimer
![image](https://github.com/user-attachments/assets/f014aede-10bf-4433-849c-2e9e3f887c26)

## Screenshot - choose from one of the option
![image](https://github.com/user-attachments/assets/b37929c3-999f-4cb1-a4d9-92624458044b)

## What's New (as of November 16 2024)
1. SteamOS 3.6.20 support

## What's New (as of June 20 2023)
1. Added 20,60 and 20,70.
2. Rewrote the systemd service to adhere to best security practices.
3. Created a simple GUI Toolbox to easily check status, change options or to completely uninstall and revert any changes made.

## Old Changelog
**March 23 2023**
1. rewrite script to use systemd service
2. additional logic for the uninstall
3. optional - check if systemd service is running via game mode

**March 21 2023**
1. added 3 options to choose from - 30,60Hz 30,70Hz and 40,70Hz

**March 16 2023**
1. initial release

## What does this script do?!?
1. The script checks if the gamescope-session is using the default values 40,60Hz refresh rates.
2. If it's the default values, the script will create a backup of the file and then "patches" accordingly to what the user has chosen.
3. The script creates a folder called ~/1RefreshRateUnlocker that contains additional helper scripts. Do not delete this folder!
4. The script checks the gamescope-session every startup if it needs to be "patched" and applies the patch if needed.
5. There is an uninstall script if end-user wants to revert any changes made.

## Prerequisites for SteamOS
1. sudo password should already be set by the end user. If sudo password is not yet set, the script will ask to set it up.

## Installation Steps
**IF YOU ARE USING AN OLDER VERSION OF THIS SCRIPT, UNINSTALL IT FIRST!**
**IF YOU WANT TO SWITCH FROM 30,60 to 40,70 etc etc, MAKE SURE TO UNINSTALL FIRST AND THEN RE-RUN THE SCRIPT!**
**[CLICK HERE FOR STEPS ON HOW TO UNINSTALL THE OLD VERSION](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/tree/7ccbc1a4e32f4244b27bf8dd15daaf39f307031a#how-to-uninstall)**
1. Go into Desktop Mode and open a konsole terminal.
2. Clone the github repo. \
   cd ~/ \
   git clone https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker.git
3. Execute the script! \
   cd ~/SteamDeck-RefreshRateUnlocker \
   chmod +x install-RefreshRateUnlocker.sh \
   ./install-RefreshRateUnlocker.sh
   
4. The script will perform several sanity checks and afterwards display a WARNING / DISCLAIMER -\
![image](https://github.com/user-attachments/assets/f014aede-10bf-4433-849c-2e9e3f887c26)
   
6. Make sure you understand the WARNING / DISCLAIMER and press YES to proceed. From here on you can choose to INSTALL or UNINSTALL -\
![image](https://github.com/user-attachments/assets/b37929c3-999f-4cb1-a4d9-92624458044b)

7. Once the install is done, reboot the Steam Deck for changes to take effect.
         

## How to Uninstall
1. Go into Desktop Mode and run the script again. Select UNINSTALL -\
![image](https://github.com/user-attachments/assets/b37929c3-999f-4cb1-a4d9-92624458044b)

2. Once the uninstall is done, reboot the Steam Deck for changes to take effect.
         
## Known Issues
1. When taking a screenshot in-game, the screen will momentarily go blank as it toggles to 60Hz, and then goes back to the custom refresh rate once the screenshot is done.

