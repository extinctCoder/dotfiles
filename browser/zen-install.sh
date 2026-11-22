#!/bin/sh
# One-time Zen setup. Run it after opening Zen once (so it creates a profile)
# and closing it again.
#   - links our user.js and userChrome.css into the default profile
#   - sets up Pywalfox (live wallpaper colors) and Zen as the default browser
#   - marks the profile for the launcher's bookmarks/history search
set -e
zen="$HOME/.config/zen" # Zen >= 1.18.6b keeps profiles here (XDG), not in ~/.zen

yay -S --needed zen-browser-bin python-pywalfox sqlite

# default profile: the [Install...] Default= entry, else the [Profile] with Default=1
ini="$zen/profiles.ini"
[ -f "$ini" ] || { echo "No Zen profile yet: open Zen once, close it, then run this again."; exit 1; }
rel=$(awk -F= '/^\[Install/{i=1;next} /^\[/{i=0} i&&$1=="Default"{print $2; exit}' "$ini")
[ -n "$rel" ] || rel=$(awk -F= '/^\[Profile/{p="";d=0} $1=="Path"{p=$2} $1=="Default"&&$2=="1"{d=1} d&&p{print p; exit}' "$ini")
case "$rel" in /*) prof="$rel" ;; *) prof="$zen/$rel" ;; esac
[ -d "$prof" ] || { echo "Could not find the default Zen profile in $ini"; exit 1; }
echo "profile: $prof"

if pgrep -x zen >/dev/null || pgrep -f zen-browser >/dev/null; then
    echo "Close Zen first, then run this again."; exit 1
fi

mkdir -p "$prof/chrome"
ln -sf "$HOME/.config/zen-theme/user.js" "$prof/user.js"
ln -sf "$HOME/.config/zen-theme/userChrome.css" "$prof/chrome/userChrome.css"
mkdir -p "$HOME/.local/state" && ln -sfn "$prof" "$HOME/.local/state/zen-profile"

# Pywalfox's native host; registered in both places Firefox-based browsers look
pywalfox install
src="$HOME/.mozilla/native-messaging-hosts/pywalfox.json"
[ -f "$src" ] && mkdir -p "$HOME/.config/mozilla/native-messaging-hosts" && cp "$src" "$HOME/.config/mozilla/native-messaging-hosts/"

xdg-settings set default-web-browser zen.desktop

# write the current colors for Pywalfox
matugen image -m dark --source-color-index 0 "$(cat "$HOME/.local/state/wallpaper")" >/dev/null 2>&1 || true

cat <<'MSG'

Done. Now open Zen and install three extensions:
  Pywalfox       https://addons.mozilla.org/firefox/addon/pywalfox/
  uBlock Origin  https://addons.mozilla.org/firefox/addon/ublock-origin/
  Bitwarden      https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/
Then click the Pywalfox icon and press "Fetch Pywal colors".
Compact mode (page only, bars on hover): Ctrl+Alt+C
MSG
