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
**[If you prefer a video tutorial then click here.](https://youtu.be/YUf-ot1t0PM)**

<p align="center">
<a href="https://youtu.be/YUf-ot1t0PM"> <img src="https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/blob/main/video.png"/> </a>
</p>


## Screenshot - choose from one of the options
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/06b7b897-d349-4bfa-8671-c1bc8a3b0120)

## Screenshot - 70Hz Display Refresh Rate
![image](https://user-images.githubusercontent.com/98122529/225729639-3bb46a85-6ffd-49ac-808d-acd518fc30ce.png)

## Screenshot - Simple GUI Toolbox
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/890fcb6f-a71f-4156-adb8-aa14b55fca75)
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/2afc4ac4-6522-4941-bdb7-b210c76ba1b0)


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
   
4. The script will check if sudo passwword is already set.\
![image](https://user-images.githubusercontent.com/98122529/225724178-364284ac-f504-4798-b5e5-a03001dda5da.png)

   a. If the sudo password is already set, enter the current sudo password and the script will continue to run. Once you see this screen then the install is done!\
![image](https://user-images.githubusercontent.com/98122529/225747904-d0352779-40ef-4dfb-afad-c473b2a9bc5b.png)

   b. If wrong sudo password is provided the script will exit immdediately. Re-run the script and enter the correct sudo password!\
![image](https://user-images.githubusercontent.com/98122529/225724539-d73dc9ce-c468-49d1-8d2c-83276bfc34bb.png)
         
   c. If the sudo password is blank / not yet set, the script will prompt to setup the sudo password. Re-run the script again to continue.\
![image](https://user-images.githubusercontent.com/98122529/225725477-33f8ffaa-13a1-452e-b993-aceb3192726f.png)


5. Make your selection.\
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/06b7b897-d349-4bfa-8671-c1bc8a3b0120)

6. Once the install is done, reboot the Steam Deck for changes to take effect.
         
7. After reboot, the custom refresh rate will be available. It can be set as high as 70Hz!\
![image](https://user-images.githubusercontent.com/98122529/225729592-a172cf55-f34c-400a-be56-e2dc68032c4e.png)

## How to Uninstall
1. Go into Desktop Mode and launch RefreshRateUnlocker Toolbox icon from the desktop.
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/1c1bb2a4-b90b-455e-9efc-269ceeb14273)

2. Select the option called Uninstall and press OK.
![image](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/assets/98122529/f76d934d-2725-49dd-9799-2cb0710ee034)

3. Once the uninstall is done, reboot the Steam Deck for changes to take effect.
         
4. After reboot, the refresh rate will be back to the default 60Hz.\
![image](https://user-images.githubusercontent.com/98122529/225729550-0ac8a2ff-79c3-4bc4-b75f-7a9388f60d74.png)

## Known Issues
1. When taking a screenshot in-game, the screen will momentarily go blank as it toggles to 60Hz, and then goes back to the custom refresh rate once the screenshot is done.

