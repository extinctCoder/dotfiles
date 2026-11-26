---@diagnostic disable: undefined-global

-- GTK apps follow the desktop: dark adw-gtk3 theme, YAMIS (or Papirus) icons, no title
-- bar buttons (Hyprland manages windows). Fonts: set by the shell's text size.
local gtk = table.concat({
    "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'",
    "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
    -- single-color icons when installed (icons/install.sh), else Papirus
    "gsettings set org.gnome.desktop.interface icon-theme \"$([ -d ~/.local/share/icons/YAMIS-matugen ] && echo YAMIS-matugen || echo Papirus-Dark)\"",
    "gsettings set org.gnome.desktop.wm.preferences button-layout ':'",
}, "; ")

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell")
    -- hidden Ghostty kept running, so `ghostty +new-window` opens windows instantly
    hl.exec_cmd("ghostty --gtk-single-instance=true --initial-window=false --quit-after-last-window-closed=false")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset") -- night light, see hyprsunset.conf
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd(gtk)
end)
