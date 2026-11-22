---@diagnostic disable: undefined-global
-- Hyprland for the login screen only. greetd runs it as the "greeter" user
-- (see /etc/greetd/config.toml). It shows the Quickshell login screen and exits
-- as soon as you log in: greetd needs the greeter's compositor gone.

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

hl.config({
    animations = { enabled = false },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = "rgb(000000)", -- black like the boot splash: no color jump
    },
    input = { kb_layout = "us", touchpad = { tap_to_click = true } },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -p /var/lib/qs-greeter/shell.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
