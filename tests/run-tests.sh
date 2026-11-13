#!/bin/bash
# End-to-end tests for install-RefreshRateUnlocker.sh (SteamOS 3.7+ method) and bootstrap.sh
# in a faked Steam Deck environment. Uses the latest Steam Deck LCD profile from upstream
# gamescope, so this also detects when Valve changes the profile in a way that breaks the mod.
#
# Usage: tests/run-tests.sh [path/to/valve.steamdeck.lcd.lua]
# Set REQUIRE_LUA=1 to fail (instead of skip) when no Lua interpreter is installed.

set -u
# identity for the test commits (the machine may have no git user configured)
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAILED=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=1; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; echo "$OUT" | sed 's/^/    /'; fi; }

# stock gamescope profile
if [ $# -ge 1 ]
then
	cp "$1" "$WORK/lcd.lua"
else
	curl -fsSL https://raw.githubusercontent.com/ValveSoftware/gamescope/master/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua -o "$WORK/lcd.lua" || { echo "Could not download the gamescope profile"; exit 1; }
fi

# stubs for the Steam Deck tools
mkdir -p "$WORK/bin" "$WORK/home"
cat > "$WORK/bin/zenity" <<'EOF'
#!/bin/bash
[[ "$*" == *--list* ]] && echo "$ZENITY_CHOICE"
exit 0
EOF
printf '#!/bin/bash\necho "[stub] steamos-session-select $*"\n' > "$WORK/bin/steamos-session-select"
printf '#!/bin/bash\n' > "$WORK/bin/sleep"
chmod +x "$WORK/bin/"*

# installer copy that reads the fake board name, os-release and profile
sed -e "s#/sys/class/dmi/id/board_name#$WORK/board_name#" \
	-e "s#\. /etc/os-release#. $WORK/os-release#" \
	-e "s#^LCD_TEMPLATE=.*#LCD_TEMPLATE=\${TEST_LCD_TEMPLATE}#" \
	"$REPO_DIR/install-RefreshRateUnlocker.sh" > "$WORK/install.sh"

SCRIPTS_DIR="$WORK/home/.config/gamescope/scripts"
PROFILE="$SCRIPTS_DIR/valve.steamdeck.lcd.70Hz.lua"

# run_installer <board> <version> <menu choice> [stock profile path]
run_installer() {
	echo "$1" > "$WORK/board_name"
	printf 'VERSION_ID=%s\n' "$2" > "$WORK/os-release"
	env -i PATH="$WORK/bin:/usr/bin:/bin" HOME="$WORK/home" WAYLAND_DISPLAY=wayland-0 \
		ZENITY_CHOICE="$3" TEST_LCD_TEMPLATE="${4:-$WORK/lcd.lua}" bash "$WORK/install.sh" 2>&1
}

echo "== installer (SteamOS 3.7+ method)"

OUT=$(run_installer Jupiter 3.9.5 INSTALL)
check "install on SteamOS 3.9.5" '[ -f "$PROFILE" ] && grep -q "successfully installed" <<< "$OUT" && grep -q "steamos-session-select gamescope" <<< "$OUT"'
check "user script sets 40..70Hz" 'grep -q "for hz = 40, 70 do" "$PROFILE"'

# the stock profile + the user script, loaded in this order like gamescope does
LUA=$(command -v lua5.4 || command -v lua5.3 || command -v lua || command -v luajit)
if [ -n "$LUA" ]
then
	OUT=$("$LUA" -e 'gamescope={config={known_displays={}},eotf={gamma22=0},modegen={}} function debug() end' \
		-e "dofile('$WORK/lcd.lua')" \
		-e 't=gamescope.config.known_displays.steamdeck_lcd before={} for k in pairs(t) do before[#before+1]=k end' \
		-e 'm,c=t.matches,t.colorimetry' \
		-e "dofile('$PROFILE')" \
		-e 'r=t.dynamic_refresh_rates assert(#r==31 and r[1]==40 and r[31]==70, "rates")' \
		-e 'for i=2,#r do assert(r[i]==r[i-1]+1, "gap") end' \
		-e 'local n=0 for k in pairs(t) do n=n+1 end assert(n==#before, "keys")' \
		-e 'assert(t.matches==m and t.colorimetry==c, "other fields")' \
		-e 'assert(t.matches({vendor="VLV", model="ANX7530 U"})==5000, "match")' 2>&1)
	check "stock profile + user script give 40..70Hz, other fields untouched (Lua)" '[ $? -eq 0 ]'
	OUT=$("$LUA" -e 'gamescope={config={known_displays={}}} function debug() end' -e "dofile('$PROFILE')" 2>&1)
	check "user script is harmless without the stock profile (Lua)" '[ $? -eq 0 ]'
elif [ "${REQUIRE_LUA:-0}" == "1" ]
then
	fail "Lua interpreter required but not found"
else
	echo "SKIP: no Lua interpreter"
fi

rm -f "$PROFILE"
OUT=$(run_installer Jupiter 3.12.1 INSTALL)
check "install on future SteamOS 3.12.1" '[ -f "$PROFILE" ] && grep -q "successfully installed" <<< "$OUT"'

OUT=$(run_installer Jupiter 3.9.5 INSTALL)
check "re-install overwrites the existing file" '[ -f "$PROFILE" ] && grep -q "successfully installed" <<< "$OUT" && [ -z "$(find "$SCRIPTS_DIR" -name ".*.tmp")" ]'

OUT=$(run_installer Jupiter 3.9.5 UNINSTALL)
check "uninstall" '[ ! -e "$PROFILE" ] && grep -q "successfully removed" <<< "$OUT"'

OUT=$(run_installer Galileo 3.9.5 INSTALL)
check "Steam Deck OLED rejected" '[ ! -e "$PROFILE" ] && grep -q "OLED detected" <<< "$OUT"'

OUT=$(run_installer Jupiter 3.9.5 INSTALL "$WORK/missing.lua")
check "missing stock profile rejected" '[ ! -e "$PROFILE" ] && grep -q "unsupported version" <<< "$OUT"'

sed 's/steamdeck_lcd/steamdeck_lcd_v2/g' "$WORK/lcd.lua" > "$WORK/renamed.lua"
OUT=$(run_installer Jupiter 3.9.5 INSTALL "$WORK/renamed.lua")
check "renamed stock profile rejected" '[ ! -e "$PROFILE" ] && grep -q "NOT successfully installed" <<< "$OUT" && ! grep -q "steamos-session-select" <<< "$OUT"'

OUT=$(run_installer Jupiter 3.9.5 EXIT)
check "cancel makes no changes" '[ ! -e "$PROFILE" ] && grep -q "Make no changes" <<< "$OUT"'

rm -rf "$SCRIPTS_DIR"; mkdir -p "$(dirname "$SCRIPTS_DIR")"; touch "$SCRIPTS_DIR"
OUT=$(run_installer Jupiter 3.9.5 INSTALL)
check "write failure is reported, not 'successfully installed'" 'grep -q "NOT successfully installed" <<< "$OUT" && ! grep -q "steamos-session-select" <<< "$OUT"'
rm -f "$SCRIPTS_DIR"

if [ "$(id -u)" != "0" ]
then
	mkdir -p "$SCRIPTS_DIR"; run_installer Jupiter 3.9.5 INSTALL > /dev/null; chmod 555 "$SCRIPTS_DIR"
	OUT=$(run_installer Jupiter 3.9.5 UNINSTALL)
	check "delete failure is reported, not 'successfully removed'" 'grep -q "Error removing" <<< "$OUT" && ! grep -q "successfully removed" <<< "$OUT"'
	chmod 755 "$SCRIPTS_DIR"
else
	echo "SKIP: delete failure test (running as root)"
fi

echo "== bootstrap.sh and .desktop launcher"

git -C "$REPO_DIR" rev-parse HEAD > /dev/null 2>&1 || { echo "not a git checkout"; exit 1; }
git clone -q --bare "$REPO_DIR" "$WORK/remote.git"
BHOME="$WORK/bhome"; BDIR="$BHOME/SteamDeck-RefreshRateUnlocker"; mkdir -p "$BHOME"
run_bootstrap() {
	env -i PATH="/usr/bin:/bin" HOME="$BHOME" GIT_CONFIG_GLOBAL=/dev/null GIT_SSH_COMMAND=false GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid RRU_REPO_URL="${1:-file://$WORK/remote.git}" bash "$REPO_DIR/bootstrap.sh" 2>&1
}
backups() { find "$BHOME" -maxdepth 1 -name 'SteamDeck-RefreshRateUnlocker.backup-*' | wc -l; }

OUT=$(run_bootstrap)
check "bootstrap: fresh download starts the installer" '[ -x "$BDIR/install-RefreshRateUnlocker.sh" ] && grep -q "Desktop Mode" <<< "$OUT"'

git --git-dir="$WORK/remote.git" --work-tree="$REPO_DIR" commit-tree -m update -p "$(git --git-dir="$WORK/remote.git" rev-parse HEAD)" "$(git --git-dir="$WORK/remote.git" rev-parse 'HEAD^{tree}')" > "$WORK/new"
git --git-dir="$WORK/remote.git" update-ref "$(git --git-dir="$WORK/remote.git" symbolic-ref HEAD)" "$(cat "$WORK/new")"
OUT=$(run_bootstrap)
check "bootstrap: updates an existing copy" '[ "$(git -C "$BDIR" rev-parse HEAD)" == "$(cat "$WORK/new")" ] && [ "$(backups)" == "0" ]'

git -C "$BDIR" remote set-url origin "file://$WORK/offline.git"
OUT=$(run_bootstrap "file://$WORK/offline.git")
check "bootstrap: offline keeps using the downloaded copy" '[ -d "$BDIR/.git" ] && grep -q "continuing with the version already downloaded" <<< "$OUT" && grep -q "Desktop Mode" <<< "$OUT"'
rm -rf "$BHOME"/SteamDeck-RefreshRateUnlocker*

OUT=$(run_bootstrap)
git -C "$BDIR" remote set-url origin "git@github.com:ryanrudolfoba/SteamDeck-RefreshRateUnlocker.git"
OUT=$(run_bootstrap "https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker.git" 2>&1 | head -1)
check "bootstrap: ssh URL of the same repository is not moved aside" '[ "$(backups)" == "0" ] && grep -q "Updating" <<< "$OUT"'
rm -rf "$BHOME"/SteamDeck-RefreshRateUnlocker*

mkdir -p "$BDIR"; git -C "$BDIR" init -q; git -C "$BDIR" remote add origin https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker.git; echo mine > "$BDIR/file.txt"
OUT=$(run_bootstrap)
check "bootstrap: copy of another repository is moved aside, not deleted" '[ "$(backups)" == "1" ] && [ -f "$(find "$BHOME" -maxdepth 1 -name "*.backup-*")/file.txt" ] && [ -x "$BDIR/install-RefreshRateUnlocker.sh" ]'
rm -rf "$BHOME"/SteamDeck-RefreshRateUnlocker*

OUT=$(run_bootstrap)
git -C "$BDIR" commit -q --allow-empty -m local
git --git-dir="$WORK/remote.git" update-ref "$(git --git-dir="$WORK/remote.git" symbolic-ref HEAD)" "$(git --git-dir="$WORK/remote.git" commit-tree -m rewritten 'HEAD^{tree}')"
OUT=$(run_bootstrap)
check "bootstrap: diverged copy is moved aside and downloaded fresh" '[ "$(backups)" == "1" ] && [ "$(git -C "$BDIR" rev-parse HEAD)" == "$(git --git-dir="$WORK/remote.git" rev-parse HEAD)" ]'

check ".desktop launcher command" 'grep -q "^Exec=konsole --hold -e bash -c \"bash <(curl -fsSL https://raw.githubusercontent.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker/main/bootstrap.sh)\"$" "$REPO_DIR/RefreshRateUnlocker.desktop"'
check "70HzLCD.sh matches install-RefreshRateUnlocker.sh" 'cmp -s "$REPO_DIR/install-RefreshRateUnlocker.sh" "$REPO_DIR/70HzLCD.sh"'

if [ $FAILED -eq 0 ]; then echo "All tests passed."; else echo "Some tests FAILED."; fi
exit $FAILED
