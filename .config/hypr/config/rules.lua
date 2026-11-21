---@diagnostic disable: undefined-global

-- system TUIs open small, floating and centered
hl.window_rule({
    match = { title = "^tui\\.float$" },
    float = true,
    center =
        true
})
-- blur behind Quickshell panels
pcall(function()
    hl.layer_rule({ match = { namespace = "^quickshell" }, blur = true })
end)
