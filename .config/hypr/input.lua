---@diagnostic disable: undefined-global

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = true, ["tap-to-click"] = true },
    },
})
-- three-finger swipe between workspaces
pcall(function()
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end)
