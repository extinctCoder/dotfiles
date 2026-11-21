---@diagnostic disable: undefined-global

-- GTK apps follow the desktop: dark adw-gtk3 theme, the mono font,
-- and no title bar buttons (Hyprland manages windows)
local gtk = table.concat({
    "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'",
    "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
    "gsettings set org.gnome.desktop.interface font-name 'FiraCode Nerd Font 11'",
    "gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font 11'",
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
