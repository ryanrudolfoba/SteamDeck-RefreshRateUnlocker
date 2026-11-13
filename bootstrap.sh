#!/bin/bash
# Downloads (or updates) SteamDeck-RefreshRateUnlocker and starts the installer.
# Used by RefreshRateUnlocker.desktop so the mod can be installed without typing commands.

REPO_URL=${RRU_REPO_URL:-https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker.git}
INSTALL_DIR=${RRU_INSTALL_DIR:-$HOME/SteamDeck-RefreshRateUnlocker}

# compare repository URLs regardless of https / ssh form, letter case and .git suffix
normalize_url() {
	echo "$1" | tr '[:upper:]' '[:lower:]' \
		| sed -e 's#^git@\([^:]*\):#https://\1/#' -e 's#^ssh://git@#https://#' -e 's#\.git$##' -e 's#/$##'
}

# keep an existing folder, just move it out of the way
move_aside() {
	BACKUP="$INSTALL_DIR.backup-$(date +%Y%m%d-%H%M%S)"
	echo "Moving the existing $INSTALL_DIR to $BACKUP"
	mv "$INSTALL_DIR" "$BACKUP" || exit 1
}

if [ -d "$INSTALL_DIR/.git" ] && [ "$(normalize_url "$(git -C "$INSTALL_DIR" remote get-url origin 2> /dev/null)")" == "$(normalize_url "$REPO_URL")" ]
then
	echo "Updating $INSTALL_DIR"
	if ! git -C "$INSTALL_DIR" fetch --quiet origin
	then
		# probably offline - the copy that is already downloaded still works
		echo "Could not check for updates - continuing with the version already downloaded."
	elif ! git -C "$INSTALL_DIR" merge --ff-only --quiet '@{upstream}'
	then
		# local changes or a rewritten history - start from a fresh copy, keep the old one
		echo "The existing copy cannot be updated - downloading a fresh one."
		move_aside
	fi
elif [ -e "$INSTALL_DIR" ]
then
	# for example a clone of the original project
	move_aside
fi

if [ ! -e "$INSTALL_DIR" ]
then
	echo "Downloading $REPO_URL"
	if ! git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
	then
		echo "Download failed. Check the internet connection and try again."
		exit 1
	fi
fi

exec "$INSTALL_DIR/install-RefreshRateUnlocker.sh"
