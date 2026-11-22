#!/bin/sh
# One-time setup of the Quickshell login screen with greetd.
# Installs and configures everything, but does NOT switch from GDM yet.
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)

sudo pacman -S --needed greetd

# shared folder: owned by you (so greeter-sync needs no sudo), readable by the greeter
sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 /var/lib/qs-greeter

sudo install -D -m 644 "$repo/greeter/hyprland.lua" /etc/greetd/hyprland.lua
[ -f /etc/greetd/config.toml ] && sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.bak
sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- --config /etc/greetd/hyprland.lua > /dev/null 2>&1"
user = "greeter"
TOML

"$HOME/.config/matugen/hooks/greeter-sync"

cat <<'MSG'

greetd is set up but not active: GDM still handles login.
Switch to the new login screen:
  sudo systemctl disable gdm && sudo systemctl enable greetd && reboot
Go back to GDM (from a console, Ctrl+Alt+F3, if the screen is stuck):
  sudo systemctl disable greetd && sudo systemctl enable gdm && reboot
MSG
