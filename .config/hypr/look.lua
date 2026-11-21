---@diagnostic disable: undefined-global

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        blur = { enabled = true, size = 6, passes = 2 },
        shadow = { enabled = false },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        allow_session_lock_restore = true, -- lets a crashed lock screen be
        restarted
    },
})
