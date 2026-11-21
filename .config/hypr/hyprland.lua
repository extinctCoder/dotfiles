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
        touchpad = { natural_scroll = true, ["tap_to_click"] = true },
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

hl.bind(mainMod .. " + w", hl.dsp.exec_cmd("ghostty --class=tui.float -e nmtui"))
hl.bind(mainMod .. " + h", hl.dsp.exec_cmd("ghostty --class=tui.float -e bluetui"))
hl.bind(mainMod .. " + a", hl.dsp.exec_cmd("ghostty --class=tui.float -e wiremix"))
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd("ghostty --class=tui.float -e btop"))
