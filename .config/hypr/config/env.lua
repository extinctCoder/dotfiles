---@diagnostic disable: undefined-global
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")

-- nmtui draws with newt; these are terminal palette names, so it follows the wallpaper
hl.env("NEWT_COLORS", "root=white,black:border=blue,black:window=white,black:shadow=black,black:title=blue,black:button=black,blue:actbutton=black,cyan:checkbox=white,black:actcheckbox=black,blue:entry=white,black:label=white,black:listbox=white,black:actlistbox=black,blue:sellistbox=blue,black:actsellistbox=black,blue:textbox=white,black:acttextbox=black,blue:helpline=white,black:roottext=white,black:emptyscale=,black:fullscale=,blue:disentry=gray,black:compactbutton=white,black")
