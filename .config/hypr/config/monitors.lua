---@diagnostic disable: undefined-global
-- Laptop screen: 1920x1080 at scale 1 (auto picked 1.5, which made everything huge).
-- Too small? Try "1.25". Run `hyprctl monitors` to see names and modes.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred", -- the panel's native mode, same as the login screen: no mode switch (flicker) at login
    position = "auto",
    scale    = "1",
})
