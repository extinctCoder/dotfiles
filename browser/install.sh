#!/bin/sh
# One-time: let matugen color Helium's toolbar and tabs from the wallpaper.
#
# Safe setup: the policy folder stays root-owned (not writable by you), and only
# color.json is yours. A writable policy folder would let any program drop
# browser policies (forced extensions, proxies...); a single writable file can
# only change the theme color.
set -e
dir=/etc/helium/policies/managed

sudo install -d -o root -g root -m 755 "$dir"
[ -f "$dir/color.json" ] || echo '{}' | sudo tee "$dir/color.json" >/dev/null
sudo chown "$(id -un):$(id -gn)" "$dir/color.json"
sudo chmod 644 "$dir/color.json"

# write the current wallpaper's color now
matugen image -m dark --source-color-index 0 "$(cat "$HOME/.local/state/wallpaper")" >/dev/null || true
echo "Helium theme color: $(cat "$dir/color.json")"
echo "Restart Helium once; after that it updates on every wallpaper change."
