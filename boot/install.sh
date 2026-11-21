#!/bin/sh
# Boot splash and quiet boot, one-time setup.
#   Plymouth theme "minimal": your laptop maker's logo (BGRT), the distro logo
#   and a progress bar. Adds quiet-boot options to /etc/kernel/cmdline and
#   rebuilds the boot images with EndeavourOS's reinstall-kernels.
# Undo:
#   sudo cp /etc/kernel/cmdline.bak /etc/kernel/cmdline
#   sudo rm /etc/dracut.conf.d/plymouth.conf /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
#   sudo reinstall-kernels
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
theme=/usr/share/plymouth/themes/minimal

sudo pacman -S --needed plymouth

# theme: the stock spinner's images (two-step needs its assets), our theme file,
# and the distro logo as the watermark
sudo install -d "$theme"
sudo cp /usr/share/plymouth/themes/spinner/*.png "$theme/"
sudo install -m 644 "$repo/boot/plymouth/minimal.plymouth" "$theme/minimal.plymouth"
logo=$(find /usr/share/endeavouros /usr/share/pixmaps -iname '*endeavouros*.png' 2>/dev/null | head -n1)
if [ -n "$logo" ]; then
    sudo cp "$logo" "$theme/watermark.png"
    echo "distro logo: $logo"
else
    echo "no EndeavourOS logo found; the splash will have no distro logo"
fi
sudo plymouth-set-default-theme minimal

# make sure dracut puts Plymouth in the boot image (it usually detects it on its own)
echo 'add_dracutmodules+=" plymouth "' | sudo tee /etc/dracut.conf.d/plymouth.conf >/dev/null

# quiet boot + splash; each option added once
[ -f /etc/kernel/cmdline.bak ] || sudo cp /etc/kernel/cmdline /etc/kernel/cmdline.bak
for opt in quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0; do
    grep -qw -- "$opt" /etc/kernel/cmdline || sudo sed -i "s|\$| $opt|" /etc/kernel/cmdline
done
echo "kernel options: $(cat /etc/kernel/cmdline)"

# no console flash between the splash and the login screen
sudo install -D -m 644 "$repo/boot/plymouth/retain-splash.conf" \
    /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
sudo systemctl daemon-reload

# rebuild boot images and entries (EndeavourOS + systemd-boot)
sudo reinstall-kernels

echo "done. Reboot to see it."
