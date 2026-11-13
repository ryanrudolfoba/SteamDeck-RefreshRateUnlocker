#!/bin/bash

clear

echo Steam Deck Refresh Rate Unlocker / 70Hz LCD mod script  by ryanrudolf
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
echo YT - 10MinuteSteamDeckGamer
echo Supports SteamOS 3.5, 3.6.20, 3.7, 3.8, 3.9 and newer.
sleep 2

# always work relative to the folder where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# capture SteamOS version and Steam Deck model
MODEL=$(cat /sys/class/dmi/id/board_name 2> /dev/null)
STEAMOS_VERSION_FULL=$(. /etc/os-release && echo "$VERSION_ID")
STEAMOS_VERSION=$(echo "$STEAMOS_VERSION_FULL" | cut -d "." -f1-2)

# refresh rate range that will be exposed to the Steam client
MIN_HZ=40
MAX_HZ=70

# SteamOS 3.7 and above: a small gamescope user script that extends the refresh rates
# of the stock Steam Deck LCD display profile (everything else stays as Valve ships it)
LCD_TEMPLATE=/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua
SCRIPT_LOCATION="${XDG_CONFIG_HOME:-$HOME/.config}/gamescope/scripts"
SCRIPT_NAME=valve.steamdeck.lcd.70Hz.lua

# SteamOS 3.6.20 unlock method using patched gamescope
# GS=GAMESCOPE
GS_ORIG="$SCRIPT_DIR/gamescope/3.6.20/gamescope-3.6.20-orig"
GS_PATCHED="$SCRIPT_DIR/gamescope/3.6.20/gamescope-3.6.20-patched"
GS_ORIG_MD5SUM=c522838a242fabe519958903253a2a4c
GS_PATCHED_MD5SUM=641af753637c710f72748d4ec7fb655b

# pick the unlock method.
# Legacy releases are matched by exact version. Everything else is detected by
# feature, not by version number: if gamescope ships the Steam Deck LCD LUA
# display profile, the LUA method is used, so new SteamOS releases keep working
# without a script update.
if [ "$STEAMOS_VERSION_FULL" == "3.6.20" ]
then
	METHOD=GAMESCOPE_BINARY
elif [ "$STEAMOS_VERSION" == "3.5" ]
then
	METHOD=GAMESCOPE_SESSION
elif [ -e "$LCD_TEMPLATE" ]
then
	METHOD=LUA
else
	METHOD=UNSUPPORTED
fi

# go back to Game Mode using the official SteamOS helper, fall back to a KDE logout
return_to_game_mode() {
	remove_temp_password
	echo Returning to Game Mode in 5sec.
	sleep 5
	if command -v steamos-session-select &> /dev/null
	then
		steamos-session-select gamescope
	elif command -v qdbus6 &> /dev/null
	then
		qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
	elif command -v qdbus &> /dev/null
	then
		qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
	else
		echo Could not switch automatically. Use the \"Return to Gaming Mode\" shortcut on the desktop.
	fi
}

report_issue() {
	echo Please open an issue report on the GitHub repo and include the output above.
}

# sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
# Desktop Mode is Wayland by default since SteamOS 3.8, so do not rely on X11 tools.
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]
then
	echo Script is running in Desktop Mode.
else
	echo Script is NOT running in Desktop Mode.
	echo Please run the script in Desktop Mode as mentioned in the README. Goodbye!
	exit 1
fi

if ! command -v zenity &> /dev/null
then
	echo zenity was not found. It is required for the dialogs. Goodbye!
	exit 1
fi

# sanity checks - make sure this is on Valve Steam Deck LCD and running on supported SteamOS version.
if [ "$MODEL" != "Jupiter" ]
then
	if [ "$MODEL" == "Galileo" ]
	then
		echo Steam Deck OLED detected. This mod is for the Steam Deck LCD only.
	else
		echo This is not a Steam Deck LCD \(board: "${MODEL:-unknown}"\). Goodbye!
	fi
	exit 1
fi

if [ "$METHOD" == "UNSUPPORTED" ]
then
	echo SteamOS "$STEAMOS_VERSION_FULL" detected. This is unsupported version.
	echo The gamescope LCD profile was not found: $LCD_TEMPLATE
	exit 1
fi
echo Test 1. Steam Deck LCD on SteamOS "$STEAMOS_VERSION_FULL" detected. Proceed to the next step.

# sudo password handling - same approach as the Decky Loader installer.
# Only the older methods (SteamOS 3.5 / 3.6.20) modify system files and need sudo.
# The LUA method (SteamOS 3.7+) only writes to the home folder, so no password is needed.
#  - password already set: ask for it in a dialog and check it
#  - no password set: set a random temporary one and remove it again when the script ends
TEMP_PASSWORD_SET=0
current_password=""

# run a command with sudo. printf (not echo -e) keeps passwords with backslashes intact,
# -k makes sudo use the password every time and not cache it after the script ends.
sudo_cmd() {
	printf '%s\n' "$current_password" | sudo -S -k "$@"
}

password_status() {
	passwd --status "$(whoami)" | tr -s " " | cut -d " " -f 2
}

remove_temp_password() {
	if [ "$TEMP_PASSWORD_SET" == "1" ]
	then
		TEMP_PASSWORD_SET=0
		if [ "$(password_status)" == "P" ]
		then
			echo Removing the temporary sudo password.
			if ! sudo_cmd passwd -d "$(whoami)" &> /dev/null
			then
				echo "Could not remove the temporary sudo password. It is: $current_password"
				echo "Change it with the passwd command."
			fi
		fi
	fi
	sudo -k 2> /dev/null
}
trap remove_temp_password EXIT

if [ "$METHOD" != "LUA" ]
then
	if [ "$(password_status)" == "P" ]
	then
		if ! current_password=$(zenity --password --title "Refresh Rate Unlocker - enter your sudo password")
		then
			echo User cancelled the password prompt. Exiting immediately.
			exit
		fi
		echo Checking if the sudo password is correct.
		if sudo_cmd true &> /dev/null
		then
			echo Sudo password is good!
		else
			echo Sudo password is wrong!
			zenity --error --title "Refresh Rate Unlocker" --text "Sudo password is wrong! Re-run the script and enter the correct sudo password." --width 400
			exit 1
		fi
	else
		# a temporary password only helps if this user is allowed to use sudo at all
		if ! id -nG | tr ' ' '\n' | grep -q -x -E 'wheel|sudo'
		then
			echo This user is not allowed to use sudo. Run the script as the deck user.
			exit 1
		fi
		echo No sudo password is set. Setting a temporary one - it will be removed when the script ends.
		current_password=$(head -c 18 /dev/urandom | base64 | tr -dc 'A-Za-z0-9')
		# mark it before calling passwd, so the EXIT trap removes it whatever happens next
		TEMP_PASSWORD_SET=1
		if ! printf '%s\n%s\n' "$current_password" "$current_password" | passwd "$(whoami)" &> /dev/null
		then
			echo Could not set a temporary sudo password. Set a password with the passwd command and re-run the script.
			exit 1
		fi
		if sudo_cmd true &> /dev/null
		then
			echo Temporary sudo password is active.
		else
			echo sudo does not accept the temporary password. Set a password with the passwd command and re-run the script.
			exit 1
		fi
	fi
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
if [ $? -ne 0 ]
then
	echo User DOES NOT agree with the terms and conditions. Exit immediately.
	exit
else
	echo User agrees to the terms and conditions. Continue with the script.
fi


###### Main menu. Ask user to UNINSTALL or INSTALL

Choice=$(zenity --width 700 --height 220 --list --radiolist --title "Refresh Rate Unlocker - SteamOS $STEAMOS_VERSION_FULL" \
	--column "Select One" \
	--column "Refresh Rate Limit" \
	--column="Description - Read this carefully!" \
	FALSE INSTALL "Install the ${MAX_HZ}Hz mod." \
	FALSE UNINSTALL "Remove the ${MAX_HZ}Hz mod." \
	TRUE EXIT "Don't make any changes and exit immediately.")

if [ $? -ne 0 ] || [ "$Choice" == "EXIT" ] || [ -z "$Choice" ]
then
	echo User pressed CANCEL / EXIT. Make no changes. Exiting immediately.
	exit

elif [ "$Choice" == "INSTALL" ]
then
	if [ "$METHOD" == "LUA" ]
	then
		echo Installing the ${MAX_HZ}Hz mod for SteamOS "$STEAMOS_VERSION_FULL".

		# the user script below modifies this table - make sure the stock profile still provides it
		if ! grep -q -E 'known_displays\.steamdeck_lcd([^A-Za-z0-9_]|$)' "$LCD_TEMPLATE" || ! grep -q -E '(^|[^A-Za-z0-9_])dynamic_refresh_rates([^A-Za-z0-9_]|$)' "$LCD_TEMPLATE"
		then
			echo ${MAX_HZ}Hz LCD mod NOT successfully installed - the stock gamescope profile has an unexpected format.
			report_issue
			exit 1
		fi

		if ! mkdir -p "$SCRIPT_LOCATION"
		then
			echo ${MAX_HZ}Hz LCD mod NOT successfully installed - could not create "$SCRIPT_LOCATION".
			exit 1
		fi

		# gamescope runs user scripts after its own display profiles, in the same Lua state,
		# so this only changes the refresh rate list of the already registered stock profile.
		TMP_FILE="$SCRIPT_LOCATION/.$SCRIPT_NAME.tmp"
		if cat > "$TMP_FILE" <<EOF && mv -f "$TMP_FILE" "$SCRIPT_LOCATION/$SCRIPT_NAME"
-- Steam Deck LCD ${MAX_HZ}Hz mod - https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
-- Extends the refresh rates of the stock Steam Deck LCD display profile to ${MIN_HZ}-${MAX_HZ}Hz.
-- Everything else (colorimetry, mode timings, panel matching) stays as shipped with SteamOS.
-- Remove this file to go back to the stock ${MIN_HZ}-60Hz range.
local lcd = gamescope.config.known_displays.steamdeck_lcd
if lcd then
    local rates = {}
    for hz = ${MIN_HZ}, ${MAX_HZ} do
        rates[#rates + 1] = hz
    end
    lcd.dynamic_refresh_rates = rates
    debug("[${MAX_HZ}Hz mod] Steam Deck LCD refresh rates set to ${MIN_HZ}-${MAX_HZ}Hz")
else
    debug("[${MAX_HZ}Hz mod] Steam Deck LCD profile not found - nothing changed")
end
EOF
		then
			echo ${MAX_HZ}Hz LCD mod successfully installed to "$SCRIPT_LOCATION/$SCRIPT_NAME"
			return_to_game_mode
		else
			rm -f "$TMP_FILE"
			echo ${MAX_HZ}Hz LCD mod NOT successfully installed - could not write "$SCRIPT_LOCATION/$SCRIPT_NAME".
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_BINARY" ]
	then
		# check the bundled files and the gamescope that is installed now
		if [ "$(md5sum "$GS_ORIG" | cut -d " " -f1)" != "$GS_ORIG_MD5SUM" ] || [ "$(md5sum "$GS_PATCHED" | cut -d " " -f1)" != "$GS_PATCHED_MD5SUM" ]
		then
			echo Hash mismatch - possible corrupt download. Clone the repo again!
			exit 1
		fi
		CURRENT_GS_MD5SUM=$(md5sum /usr/bin/gamescope | cut -d " " -f1)
		if [ "$CURRENT_GS_MD5SUM" == "$GS_PATCHED_MD5SUM" ]
		then
			echo The 70Hz mod is already installed.
			exit
		elif [ "$CURRENT_GS_MD5SUM" != "$GS_ORIG_MD5SUM" ]
		then
			echo The installed gamescope is not the stock SteamOS 3.6.20 version. Not touching it.
			report_issue
			exit 1
		fi

		echo Installing the 70Hz mod for SteamOS "$STEAMOS_VERSION_FULL".
		sudo_cmd steamos-readonly disable &> /dev/null
		sudo_cmd cp "$GS_PATCHED" /usr/bin/gamescope
		sudo_cmd steamos-readonly enable &> /dev/null
		if [ "$(md5sum /usr/bin/gamescope | cut -d " " -f 1)" == "$GS_PATCHED_MD5SUM" ]
		then
			echo 70Hz mod successfully installed.
			return_to_game_mode
		else
			echo Error installing the 70Hz mod.
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_SESSION" ]
	then
		echo Installing the 70Hz mod for SteamOS "$STEAMOS_VERSION_FULL".
		sudo_cmd steamos-readonly disable &> /dev/null
		sudo_cmd sed -i 's/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=40,70/g' /bin/gamescope-session
		sudo_cmd steamos-readonly enable &> /dev/null
		if grep -q "STEAM_DISPLAY_REFRESH_LIMITS=40,70" /bin/gamescope-session
		then
			echo 70Hz mod successfully installed.
			return_to_game_mode
		else
			echo Error installing the 70Hz mod.
			exit 1
		fi
	fi

elif [ "$Choice" == "UNINSTALL" ]
then
	if [ "$METHOD" == "LUA" ]
	then
		echo Removing the ${MAX_HZ}Hz mod for SteamOS "$STEAMOS_VERSION_FULL".
		rm -f "$SCRIPT_LOCATION/$SCRIPT_NAME"
		if [ ! -e "$SCRIPT_LOCATION/$SCRIPT_NAME" ]
		then
			echo ${MAX_HZ}Hz mod successfully removed.
			return_to_game_mode
		else
			echo Error removing "$SCRIPT_LOCATION/$SCRIPT_NAME" - delete it manually.
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_BINARY" ]
	then
		if [ "$(md5sum "$GS_ORIG" | cut -d " " -f1)" != "$GS_ORIG_MD5SUM" ]
		then
			echo Hash mismatch - possible corrupt download. Clone the repo again! Nothing was changed.
			exit 1
		fi
		if [ "$(md5sum /usr/bin/gamescope | cut -d " " -f1)" == "$GS_ORIG_MD5SUM" ]
		then
			echo The 70Hz mod is not installed - gamescope is already the stock version.
			exit
		fi

		echo Removing the 70Hz mod for SteamOS "$STEAMOS_VERSION_FULL".
		sudo_cmd steamos-readonly disable &> /dev/null
		sudo_cmd cp "$GS_ORIG" /usr/bin/gamescope
		sudo_cmd steamos-readonly enable &> /dev/null
		if [ "$(md5sum /usr/bin/gamescope | cut -d " " -f 1)" == "$GS_ORIG_MD5SUM" ]
		then
			echo 70Hz mod successfully removed.
			exit
		else
			echo Error removing the 70Hz mod.
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_SESSION" ]
	then
		echo Removing the 70Hz mod for SteamOS "$STEAMOS_VERSION_FULL".
		sudo_cmd steamos-readonly disable &> /dev/null
		sudo_cmd sed -i 's/STEAM_DISPLAY_REFRESH_LIMITS=40,70/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g' /bin/gamescope-session
		sudo_cmd steamos-readonly enable &> /dev/null
		if grep -q "STEAM_DISPLAY_REFRESH_LIMITS=40,60" /bin/gamescope-session
		then
			echo 70Hz mod successfully removed.
			exit
		else
			echo Error removing the 70Hz mod.
			exit 1
		fi
	fi
fi
