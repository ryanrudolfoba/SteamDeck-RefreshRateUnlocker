#!/bin/bash
# Tests for the legacy SteamOS 3.5 / 3.6.20 methods and the Decky-style sudo password handling.
# Creates real test users (needs root, sudo and passwd), so run it in a throwaway machine / CI:
#   sudo bash tests/run-legacy-tests.sh

set -u
if [ "$(id -u)" != "0" ]; then echo "Run as root (it creates test users)."; exit 1; fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=$(mktemp -d /tmp/rru-legacy.XXXXXX)
chmod 755 "$WORK"
SUDO_USER_NAME=rrudeck
NOSUDO_USER_NAME=rrunosudo
STUB_READONLY=/usr/local/bin/steamos-readonly
FAILED=0

cleanup() {
	userdel -r "$SUDO_USER_NAME" &> /dev/null
	userdel -r "$NOSUDO_USER_NAME" &> /dev/null
	rm -f /etc/sudoers.d/rru-legacy-test "$STUB_READONLY"
	rm -rf "$WORK"
}
trap cleanup EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=1; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; echo "$OUT" | sed 's/^/    /'; fi; }

[ -e "$STUB_READONLY" ] && { echo "$STUB_READONLY already exists - refusing to overwrite it"; exit 1; }
printf '#!/bin/bash\nexit 0\n' > "$STUB_READONLY"; chmod 755 "$STUB_READONLY"

# test users: one allowed to use sudo (like deck on SteamOS, group wheel), one that is not
getent group wheel > /dev/null || groupadd wheel
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/rru-legacy-test; chmod 440 /etc/sudoers.d/rru-legacy-test
useradd -m -G wheel "$SUDO_USER_NAME"
useradd -m "$NOSUDO_USER_NAME"

# stubs and a copy of the installer that uses test files instead of system files
mkdir -p "$WORK/bin"
cat > "$WORK/bin/zenity" <<'EOF'
#!/bin/bash
[[ "$*" == *--password* ]] && { printf '%s\n' "$ZENITY_PW"; exit 0; }
[[ "$*" == *--list* ]] && echo "$ZENITY_CHOICE"
exit 0
EOF
printf '#!/bin/bash\necho "[stub] steamos-session-select $*"\n' > "$WORK/bin/steamos-session-select"
printf '#!/bin/bash\n' > "$WORK/bin/sleep"
cp -r "$REPO_DIR/gamescope" "$WORK/"
sed -e "s#/sys/class/dmi/id/board_name#$WORK/board_name#" \
	-e "s#\. /etc/os-release#. $WORK/os-release#" \
	-e "s#/usr/bin/gamescope#$WORK/usr-bin-gamescope#g" \
	-e "s#/bin/gamescope-session#$WORK/bin-gamescope-session#g" \
	"$REPO_DIR/install-RefreshRateUnlocker.sh" > "$WORK/install-RefreshRateUnlocker.sh"
echo Jupiter > "$WORK/board_name"
chmod -R a+rX "$WORK"; chmod +x "$WORK/bin/"* "$WORK/install-RefreshRateUnlocker.sh"

# shellcheck disable=SC2034  # used inside the check expressions
GS_ORIG_MD5=c522838a242fabe519958903253a2a4c
# shellcheck disable=SC2034
GS_PATCHED_MD5=641af753637c710f72748d4ec7fb655b
gs_md5() { md5sum "$WORK/usr-bin-gamescope" | cut -d " " -f1; }
pw_status() { passwd --status "$1" | tr -s " " | cut -d " " -f 2; }

# run_as <user> <SteamOS version> <menu choice> [password typed into the dialog]
run_as() {
	printf 'VERSION_ID=%s\n' "$2" > "$WORK/os-release"
	su "$1" -s /bin/bash -c "env -i PATH=$WORK/bin:/usr/local/bin:/usr/bin:/bin HOME=/home/$1 WAYLAND_DISPLAY=wayland-0 ZENITY_CHOICE=$3 ZENITY_PW=\"\$RRU_PW\" $WORK/install-RefreshRateUnlocker.sh" 2>&1
}

echo "== SteamOS 3.6.20 (patched gamescope binary) and temporary password"
cp "$WORK/gamescope/3.6.20/gamescope-3.6.20-orig" "$WORK/usr-bin-gamescope"
passwd -d "$SUDO_USER_NAME" > /dev/null

OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 INSTALL)
check "no password: temporary password set, install done, password removed again" '[ "$(gs_md5)" == "$GS_PATCHED_MD5" ] && grep -q "Temporary sudo password is active" <<< "$OUT" && grep -q "Removing the temporary sudo password" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'
check "no sudo rights are left cached after the script" '! su "$SUDO_USER_NAME" -c "sudo -n true" &> /dev/null'

OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 INSTALL)
check "install again: reports already installed" 'grep -q "already installed" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'

OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 EXIT)
check "cancel after the temporary password was set removes it" 'grep -q "Make no changes" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'

OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 UNINSTALL)
check "uninstall restores the stock gamescope, password removed" '[ "$(gs_md5)" == "$GS_ORIG_MD5" ] && grep -q "successfully removed" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'

echo 'not gamescope' > "$WORK/usr-bin-gamescope"
OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 INSTALL)
check "unknown installed gamescope is not replaced" '[ "$(cat "$WORK/usr-bin-gamescope")" == "not gamescope" ] && grep -q "not the stock SteamOS 3.6.20" <<< "$OUT"'

cp "$WORK/gamescope/3.6.20/gamescope-3.6.20-patched" "$WORK/usr-bin-gamescope"
cp "$WORK/gamescope/3.6.20/gamescope-3.6.20-orig" "$WORK/orig.bak"; echo corrupt > "$WORK/gamescope/3.6.20/gamescope-3.6.20-orig"
OUT=$(run_as "$SUDO_USER_NAME" 3.6.20 UNINSTALL)
check "uninstall with a corrupt bundled file changes nothing" '[ "$(gs_md5)" == "$GS_PATCHED_MD5" ] && grep -q "Hash mismatch" <<< "$OUT"'
cp "$WORK/orig.bak" "$WORK/gamescope/3.6.20/gamescope-3.6.20-orig"

echo "== existing password"
PW='pa\ss\nword\c'
echo "$SUDO_USER_NAME:$PW" | chpasswd
OUT=$(RRU_PW="$PW" run_as "$SUDO_USER_NAME" 3.6.20 UNINSTALL)
check "password with backslashes is accepted" 'grep -q "Sudo password is good" <<< "$OUT" && [ "$(gs_md5)" == "$GS_ORIG_MD5" ]'
check "existing password is kept" 'printf "%s\n" "$PW" | su "$SUDO_USER_NAME" -c "sudo -S -k true" &> /dev/null'

cp "$WORK/gamescope/3.6.20/gamescope-3.6.20-orig" "$WORK/usr-bin-gamescope"
OUT=$(RRU_PW='wrong' run_as "$SUDO_USER_NAME" 3.6.20 INSTALL)
check "wrong password is rejected, nothing changed" 'grep -q "Sudo password is wrong" <<< "$OUT" && [ "$(gs_md5)" == "$GS_ORIG_MD5" ] && [ "$(pw_status "$SUDO_USER_NAME")" == "P" ]'

echo "== user without sudo rights"
passwd -d "$NOSUDO_USER_NAME" > /dev/null
OUT=$(run_as "$NOSUDO_USER_NAME" 3.6.20 INSTALL)
check "no temporary password is set for a user without sudo rights" 'grep -q "not allowed to use sudo" <<< "$OUT" && [ "$(pw_status "$NOSUDO_USER_NAME")" == "NP" ] && [ "$(gs_md5)" == "$GS_ORIG_MD5" ]'

echo "== SteamOS 3.5 (gamescope-session)"
passwd -d "$SUDO_USER_NAME" > /dev/null
printf '#!/bin/bash\nexport STEAM_DISPLAY_REFRESH_LIMITS=40,60\n' > "$WORK/bin-gamescope-session"
OUT=$(run_as "$SUDO_USER_NAME" 3.5.19 INSTALL)
check "3.5 install sets 40,70" 'grep -q "STEAM_DISPLAY_REFRESH_LIMITS=40,70" "$WORK/bin-gamescope-session" && grep -q "successfully installed" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'
OUT=$(run_as "$SUDO_USER_NAME" 3.5.19 UNINSTALL)
check "3.5 uninstall restores 40,60" 'grep -q "STEAM_DISPLAY_REFRESH_LIMITS=40,60" "$WORK/bin-gamescope-session" && grep -q "successfully removed" <<< "$OUT" && [ "$(pw_status "$SUDO_USER_NAME")" == "NP" ]'
printf '#!/bin/bash\n# something else\n' > "$WORK/bin-gamescope-session"
OUT=$(run_as "$SUDO_USER_NAME" 3.5.19 UNINSTALL)
check "3.5 uninstall reports an error when there is nothing to restore" 'grep -q "Error removing" <<< "$OUT" && ! grep -q "successfully removed" <<< "$OUT"'

if [ $FAILED -eq 0 ]; then echo "All legacy tests passed."; else echo "Some legacy tests FAILED."; fi
exit $FAILED
