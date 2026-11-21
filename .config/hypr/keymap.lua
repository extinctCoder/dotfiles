-- { keys, action, description, group }
-- action: text starting with "hl." is a Lua dispatcher; anything else is a shell command
-- Pure data (no hl.* calls), so Quickshell can read it with plain `lua`.
local M = { binds = {}, leader = {} }

local function bind(keys, action, desc, group)
    table.insert(M.binds, { keys, action, desc, group })
end
local function leader(key, cmd, desc)
    table.insert(M.leader, { key, cmd, desc })
end
local tui = "ghostty --class=tui.float -e "
local shots = "hyprshot -o ~/Pictures/Screenshots -m "

-- apps and shell
bind("SUPER + return", "ghostty", "terminal", "apps")
bind("SUPER + space", "qs ipc call launcher toggle", "launcher", "apps")
bind("SUPER + v", "qs ipc call launcher clipboard", "clipboard history", "apps")
bind("SUPER + d", "qs ipc call keys leader", "leader menu", "apps")
bind("SUPER + slash", "qs ipc call keys cheatsheet", "keybind cheatsheet", "apps")
bind("SUPER + n", "qs ipc call notifs clear", "clear notifications", "apps")

-- windows (vim directions)
bind("SUPER + q", "hl.dsp.window.close()", "close window", "windows")
bind("SUPER + f", "hl.dsp.window.fullscreen()", "fullscreen", "windows")
bind("SUPER + t", 'hl.dsp.window.float({ action = "toggle" })', "toggle floating", "windows")
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    bind("SUPER + " .. key, 'hl.dsp.focus({ direction = "' .. dir .. '" })', "focus " .. dir, "windows")
    bind("SUPER + SHIFT + " .. key, 'hl.dsp.window.move({ direction = "' .. dir .. '" })', "move window " .. dir, "windows")
end

-- workspaces
for i = 1, 9 do
    bind("SUPER + " .. i, "hl.dsp.focus({ workspace = " .. i .. " })", "workspace " .. i, "workspaces")
    bind("SUPER + SHIFT + " .. i, "hl.dsp.window.move({ workspace = " .. i .. " })", "send to workspace " .. i, "workspaces")
end

-- system
bind("SUPER + escape", "qs ipc call lock lock", "lock screen", "system")
bind("print", shots .. "region", "screenshot region", "system")
bind("SHIFT + print", shots .. "output", "screenshot screen", "system")

-- laptop keys
bind("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "volume up", "media")
bind("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "volume down", "media")
bind("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "mute", "media")
bind("XF86MonBrightnessUp", "brightnessctl set 5%+", "brightness up", "media")
bind("XF86MonBrightnessDown", "brightnessctl set 5%-", "brightness down", "media")
bind("XF86AudioPlay", "playerctl play-pause", "play / pause", "media")
bind("XF86AudioNext", "playerctl next", "next track", "media")
bind("XF86AudioPrev", "playerctl previous", "previous track", "media")

-- leader menu: SUPER + d, then one key (shell commands only)
leader("t", "ghostty", "terminal")
leader("b", "helium-browser", "browser")
leader("f", "ghostty -e yazi", "files")
leader("e", "ghostty -e nvim", "editor")
leader("w", tui .. "nmtui", "wifi")
leader("h", tui .. "bluetui", "bluetooth")
leader("a", tui .. "wiremix", "audio")
leader("m", tui .. "btop", "monitor")
leader("p", "qs ipc call wallpaper next", "next wallpaper")
leader("s", shots .. "region", "screenshot")
leader("l", "qs ipc call lock lock", "lock")
leader("z", "systemctl suspend", "sleep")

return M
