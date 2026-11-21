---@diagnostic disable: undefined-global

local mainMod = "SUPER"

hl.config({
    general = { gaps_in = 4, gaps_out = 8, border_size = 1 },
    decoration = {
        rounding = 0,
        blur = { enabled = true, size = 6, passes = 2 },
        shadow = { enabled = false }
    },
    input = {
        touchpad = { natural_scroll = true, ["tap-to-click"] = true },
    }
})

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --watch cliphist store")
end)

-- float and center the system TUIs from step 8
hl.window_rule({
    match = { class = "^tui\\.float$" },
    float = true,
    center = true
})

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
