-- { keys, action, description, group, flags }
-- action: text starting with "hl." is a Lua dispatcher; anything else is a shell command
-- flags (optional): hl.bind flags, e.g. { locked = true, repeating = true }
-- Pure data (no hl.* calls), so Quickshell can read it with plain `lua`.
local M = { binds = {}, leader = {} }

local function bind(keys, action, desc, group, flags)
    table.insert(M.binds, { keys, action, desc, group, flags })
end
local function leader(key, cmd, desc)
    table.insert(M.leader, { key, cmd, desc })
end
local term = "ghostty +new-window"          -- fast: reuses the running Ghostty
local tui = term .. " --title=tui.float -e " -- small floating window (rules.lua)
local shots = "hyprshot -o ~/Pictures/Screenshots -m "
local media = { locked = true, repeating = true } -- hold to repeat, works on the lock screen
local locked = { locked = true }

-- apps
bind("SUPER + return", term, "terminal", "apps")
bind("SUPER + b", "helcanium", "browser", "apps")
bind("SUPER + e", term .. " -e yazi", "files", "apps")
bind("SUPER + c", term .. " -e nvim", "editor", "apps")
bind("SUPER + m", tui .. "btop", "monitor", "apps")

-- shell
bind("SUPER + space", "qs ipc call launcher toggle", "launcher", "shell")
bind("SUPER + v", "qs ipc call launcher clipboard", "clipboard history", "shell")
bind("SUPER + d", "qs ipc call keys leader", "leader menu", "shell")
bind("SUPER + slash", "qs ipc call keys cheatsheet", "keybind cheatsheet", "shell")
bind("SUPER + n", "qs ipc call notifs clear", "clear notifications", "shell")
bind("SUPER + a", "qs ipc call quick toggle", "quick settings + notifications", "shell")
bind("SUPER + w", "qs ipc call picker toggle", "wallpaper picker", "shell")

-- windows (vim directions)
bind("SUPER + q", "hl.dsp.window.close()", "close window", "windows")
bind("SUPER + f", "hl.dsp.window.fullscreen()", "fullscreen", "windows")
bind("SUPER + t", 'hl.dsp.window.float({ action = "toggle" })', "toggle floating", "windows")
bind("SUPER + x", 'hl.dsp.layout("togglesplit")', "flip split direction", "windows")
local step = { h = { -40, 0 }, j = { 0, 40 }, k = { 0, -40 }, l = { 40, 0 } }
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    bind("SUPER + " .. key, 'hl.dsp.focus({ direction = "' .. dir .. '" })', "focus " .. dir, "windows")
    bind("SUPER + SHIFT + " .. key, 'hl.dsp.window.move({ direction = "' .. dir .. '" })', "move window " .. dir, "windows")
    bind("SUPER + CTRL + " .. key,
        "hl.dsp.window.resize({ x = " .. step[key][1] .. ", y = " .. step[key][2] .. ", relative = true })",
        "resize " .. dir, "windows", { repeating = true })
end

-- workspaces
for i = 1, 9 do
    bind("SUPER + " .. i, "hl.dsp.focus({ workspace = " .. i .. " })", "workspace " .. i, "workspaces")
    bind("SUPER + SHIFT + " .. i, "hl.dsp.window.move({ workspace = " .. i .. " })", "send to workspace " .. i, "workspaces")
end
bind("SUPER + mouse_down", 'hl.dsp.focus({ workspace = "e+1" })', "next workspace", "workspaces")
bind("SUPER + mouse_up", 'hl.dsp.focus({ workspace = "e-1" })', "previous workspace", "workspaces")
bind("SUPER + s", 'hl.dsp.workspace.toggle_special("magic")', "show / hide scratchpad", "workspaces")
bind("SUPER + SHIFT + s", 'hl.dsp.window.move({ workspace = "special:magic" })', "send to scratchpad", "workspaces")

-- system
bind("SUPER + escape", "qs ipc call lock lock", "lock screen", "system")
bind("SUPER + SHIFT + e", "hl.dsp.exit()", "log out of Hyprland", "system")
bind("SUPER + SHIFT + escape", "qs ipc call power toggle", "power menu", "system")
bind("print", shots .. "region", "screenshot region", "system")
bind("SHIFT + print", shots .. "output", "screenshot screen", "system")

-- laptop keys
bind("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "volume up", "media", media)
bind("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "volume down", "media", media)
bind("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "mute", "media", locked)
bind("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "mic mute", "media", locked)
bind("XF86MonBrightnessUp", "brightnessctl set 5%+ && qs ipc call brightness refresh", "brightness up", "media", media)
bind("XF86MonBrightnessDown", "brightnessctl set 5%- && qs ipc call brightness refresh", "brightness down", "media", media)
bind("XF86AudioPlay", "playerctl play-pause", "play / pause", "media", locked)
bind("XF86AudioPause", "playerctl play-pause", "play / pause", "media", locked)
bind("XF86AudioNext", "playerctl next", "next track", "media", locked)
bind("XF86AudioPrev", "playerctl previous", "previous track", "media", locked)

-- leader menu: SUPER + d, then one key (shell commands only)
leader("t", term, "terminal")
leader("b", "helcanium", "browser")
leader("f", term .. " -e yazi", "files")
leader("e", term .. " -e nvim", "editor")
leader("w", tui .. "nmtui", "wifi")
leader("h", tui .. "bluetui", "bluetooth")
leader("a", tui .. "wiremix", "audio")
leader("m", tui .. "btop", "monitor")
leader("p", "qs ipc call picker toggle", "wallpaper picker")
leader("P", "qs ipc call wallpaper next", "random wallpaper")
leader("s", shots .. "region", "screenshot")
leader("l", "qs ipc call lock lock", "lock")
leader("z", "systemctl suspend", "sleep")
leader("r", "systemctl reboot", "reboot")
leader("x", "systemctl poweroff", "shut down")

return M
