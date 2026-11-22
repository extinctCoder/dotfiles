---@diagnostic disable: undefined-global

hl.config({
    -- shown for a moment at login, before the wallpaper is drawn
    misc = { background_color = "rgb({{colors.surface.default.hex_stripped}})" },
    general = {
        col = {
            active_border = "rgb({{colors.primary.default.hex_stripped}})",
            inactive_border =
            "rgb({{colors.outline_variant.default.hex_stripped}})",
        },
    },
})
