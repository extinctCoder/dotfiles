#!/bin/sh
# One-time setup for YouTube in mpv (and lyrics by ear: songrec, a Shazam client):
#   mpv + yt-dlp (best quality), mpv-mpris (island, lyrics, media keys),
#   uosc (flat controls in your colors), SponsorBlock, ff2mpv (Zen -> mpv).
# Some packages put their scripts where mpv loads them (/etc/mpv/scripts),
# others in /usr/share/mpv; this asks pacman where each one went and links
# only what mpv would not load on its own.
set -e
yay -S --needed mpv yt-dlp mpv-mpris mpv-uosc mpv-sponsorblock-minimal-git ff2mpv-native-messaging-host-git songrec

conf="$HOME/.config/mpv"
mkdir -p "$conf/scripts" "$conf/script-opts"

for pkg in mpv-mpris mpv-uosc mpv-sponsorblock-minimal-git; do
    if pacman -Ql "$pkg" | grep -q " /etc/mpv/scripts/."; then
        echo "$pkg: loaded by mpv already"
        continue
    fi
    # top-level entries under .../mpv/scripts/ (a script file or a script folder)
    pacman -Ql "$pkg" | awk '{print $2}' | grep -E '/mpv/scripts/[^/]+/?$' | while read -r p; do
        p=${p%/}
        ln -sfn "$p" "$conf/scripts/$(basename "$p")"
        echo "$pkg: linked $(basename "$p")"
    done
done

# uosc's icon font
uf=$(pacman -Ql mpv-uosc | awk '{print $2}' | grep -E '/mpv/fonts/?$' | head -n 1)
[ -n "$uf" ] && ln -sfn "${uf%/}" "$conf/fonts" && echo "mpv-uosc: linked fonts"

# ff2mpv's native host: the package registers it system-wide; also register it
# per user, in both places Firefox-based browsers (Zen) look
m=$(pacman -Ql ff2mpv-native-messaging-host-git | awk '{print $2}' | grep 'native-messaging-hosts/ff2mpv.json$' | head -n 1)
for d in "$HOME/.mozilla/native-messaging-hosts" "$HOME/.config/mozilla/native-messaging-hosts"; do
    [ -n "$m" ] && mkdir -p "$d" && cp "$m" "$d/" && echo "ff2mpv: registered in $d"
done

# write the colors for uosc now
matugen image -m dark --source-color-index 0 "$(cat "$HOME/.local/state/wallpaper")" >/dev/null 2>&1 || true

cat <<'MSG'

Done. Last step, in Zen: install the ff2mpv extension
  https://addons.mozilla.org/firefox/addon/ff2mpv/
Then on any YouTube page: right-click > "Play in MPV" (or its toolbar button).
MSG
