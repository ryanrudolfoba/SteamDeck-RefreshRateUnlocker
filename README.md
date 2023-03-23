# SteamDeck Refresh Rate Unlocker
This repository contains the instructions and scripts on how to unlock the Steam Deck under SteamOS to use upto 70Hz refresh rate for the display (do not confuse this with FPS). \
Discord user dan2wik for the idea on overclocking the display panel to 70Hz!

## Disclaimer
1. Do this at your own risk!
2. This is for educational and research purposes only!

## Screenshot - choose from one of the options
![image](https://user-images.githubusercontent.com/98122529/226790044-33a74e6a-bd1b-480a-a6f6-fca891d8aed6.png)

## Screenshot - 70Hz Display Refresh Rate
![image](https://user-images.githubusercontent.com/98122529/225729639-3bb46a85-6ffd-49ac-808d-acd518fc30ce.png)

## Screenshot - Check if systemd service is running from game mode
![image](https://user-images.githubusercontent.com/98122529/227315863-6abdc854-541e-4938-a7be-405d7a38a7ca.png)
![image](https://user-images.githubusercontent.com/98122529/227315943-e3d8273e-e10b-4415-8df4-6f558e283f89.png)


## What's New (as of March 23 2023)
1. rewrite script to use systemd service
2. additional logic for the uninstall
3. optional - check if systemd service is running via game mode

## Old Changelog
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
** IF YOU WANT TO SWITCH FROM 30,60 to 40,70 etc etc, MAKE SURE TO UNINSTALL FIRST AND THEN RE-RUN THE SCRIPT!**
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
![image](https://user-images.githubusercontent.com/98122529/226789985-311f4632-f1a7-4c6c-9862-a03872f9276d.png)

6. Once the install is done, reboot the Steam Deck for changes to take effect.
         
7. After reboot, the custom refresh rate will be available. It can be set as high as 70Hz!\
![image](https://user-images.githubusercontent.com/98122529/225729592-a172cf55-f34c-400a-be56-e2dc68032c4e.png)


## Optional - Add as non-steam game to easily check if the system service is running
When a branch change occurs or when a SteamOS update happens, the custom systemd service can get wiped out.\
When this happens, just reboot back to Desktop Mode and run the ~/1RefreshRateUnlocker/reinstall-service.sh script.\
Do the steps below to easily check if the systemd service is running or not.
1. Go to Desktop Mode and open up the Steam Client.
2. On the lower left, click Add Game > Add a Non-Steam Game.
3. Select any item from the list it doesn't matter as we will change the parameters later on. For this example I chose Ark, and the press Add Selected Programs.\
![image](https://user-images.githubusercontent.com/98122529/227317668-d0a39f51-374a-4452-9216-e639ba2618d9.png) \
4. Find the Ark from the list and select Properties.
5. Change the shorcut name to 1 - Refresh Rate Unlocker Service Status.
6. For the target, leave it blank.
7. For the start in, leave it blank.
8. For the launch option, enter - /home/deck/1RefreshRateUnlocker/check-service-status.sh 
9. This is how it should look like - 
![image](https://user-images.githubusercontent.com/98122529/227318467-c75a1f80-db0f-42a3-8c5a-366946f09798.png) \
10. If everything looks OK just close that screen. Run the shortcut to verify it works.
![image](https://user-images.githubusercontent.com/98122529/227318770-7d921d05-5013-4b62-b476-e98dc490bbee.png) \


## How to Uninstall
1. Go into Desktop Mode and open a konsole terminal.
2. Execute the uninstall script! \
   cd ~/1RefreshRateUnlocker \
   ./uninstall-RefreshRateUnlocker.sh \
![image](https://user-images.githubusercontent.com/98122529/225728420-774e83bc-977f-4420-acb8-047f0f5a0f1e.png)
   
3. Once the uninstall is done, reboot the Steam Deck for changes to take effect.
         
5. After reboot, the refresh rate will be back to the default 60Hz.\
![image](https://user-images.githubusercontent.com/98122529/225729550-0ac8a2ff-79c3-4bc4-b75f-7a9388f60d74.png)

## Known Issues
1. When taking a screenshot in-game, the screen will momentarily go blank as it toggles to 60Hz, and then goes back to the custom refresh rate once the screenshot is done.

