#!/bin/sh
# One-time: single-color app icons that follow the wallpaper.
#   - installs YAMIS (Yet Another Monochrome Icon Set, GPL-3.0, by dirn)
#   - writes the recolored copy (~/.local/share/icons/YAMIS-matugen) in the
#     current accent; matugen rewrites it on every wallpaper change
#   - makes GTK apps use it (Papirus-Dark stays the fallback for icons YAMIS
#     doesn't have; Qt apps keep Papirus-Dark)
# Undo: gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
set -e
yay -S --needed yamis-icon-theme-git papirus-icon-theme

accent=$(cat "$HOME/.cache/icon-accent" 2>/dev/null || echo '#d8dee9')
"$HOME/.config/matugen/hooks/icons-recolor" "$accent"
[ -d "$HOME/.local/share/icons/YAMIS-matugen" ] || { echo "YAMIS was not found after installing; nothing changed."; exit 1; }

# Hyprland's autostart picks YAMIS-matugen from now on (when it exists); set it now too
gsettings set org.gnome.desktop.interface icon-theme 'YAMIS-matugen'
echo "Done. Apps that are already open pick up the new icons when restarted."
