pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import qs.theme

// Everything the launcher can do besides opening apps. Each action:
// { name, glyph, keywords, confirm (ask twice), run }
Singleton {
    id: root
    function shot(mode) { Quickshell.execDetached(["sh", "-c", "hyprshot -o ~/Pictures/Screenshots -m " + mode]); }

    readonly property var all: [
        { name: "lock", glyph: Icons.lock, keywords: "screen", run: () => Power.run(Power.actions[0]) },
        { name: "log out", glyph: Icons.logout, keywords: "exit session hyprland", run: () => Power.run(Power.actions[1]) },
        { name: "sleep", glyph: Icons.sleep, keywords: "suspend", run: () => Power.run(Power.actions[2]) },
        { name: "reboot", glyph: Icons.restart, keywords: "restart", confirm: true, run: () => Power.run(Power.actions[3]) },
        { name: "shut down", glyph: Icons.power, keywords: "poweroff off", confirm: true, run: () => Power.run(Power.actions[4]) },
        { name: "wallpaper picker", glyph: Icons.image, keywords: "background theme colors", run: () => Panels.open = "picker" },
        { name: "random wallpaper", glyph: Icons.shuffle, keywords: "background next", run: () => Wall.next() },
        { name: "night light", glyph: Icons.night, keywords: "warm sunset toggle", run: () => Sunset.toggle() },
        { name: "silent", glyph: Icons.bellOff, keywords: "do not disturb dnd notifications toggle", run: () => Notifs.dnd = !Notifs.dnd },
        { name: "stay awake", glyph: Icons.coffee, keywords: "caffeine idle inhibit toggle", run: () => Session.stayAwake = !Session.stayAwake },
        { name: "wi-fi on/off", glyph: Icons.wifi, keywords: "wireless network radio toggle", run: () => Wifi.setRadio(!Wifi.radio) },
        { name: "bluetooth on/off", glyph: Icons.bluetooth, keywords: "toggle", run: () => { const a = Bluetooth.defaultAdapter; if (a) a.enabled = !a.enabled; } },
        { name: "screenshot region", glyph: Icons.screenshot, keywords: "capture area", run: () => root.shot("region") },
        { name: "screenshot screen", glyph: Icons.screenshot, keywords: "capture monitor full", run: () => root.shot("output") },
        { name: "clipboard history", glyph: Icons.clipboard, keywords: "paste copy", run: () => Panels.open = "clip" },
        { name: "keybinds", glyph: Icons.keyboard, keywords: "cheatsheet shortcuts help", run: () => Panels.open = "sheet" },
        { name: "quick settings", glyph: Icons.tune, keywords: "notifications panel", run: () => Panels.open = "quick" },
        { name: "window overview", glyph: Icons.grid, keywords: "windows workspaces expose", run: () => Panels.open = "overview" },
        { name: "power mode eco", glyph: Icons.battery, keywords: "saver profile", run: () => PowerProfiles.profile = PowerProfile.PowerSaver },
        { name: "power mode balanced", glyph: Icons.battery, keywords: "profile bal", run: () => PowerProfiles.profile = PowerProfile.Balanced },
        { name: "power mode performance", glyph: Icons.battery, keywords: "profile perf fast", run: () => PowerProfiles.profile = PowerProfile.Performance },
        { name: "text small", glyph: Icons.textSize, keywords: "font size", run: () => TextSize.set(0.9) },
        { name: "text medium", glyph: Icons.textSize, keywords: "font size normal", run: () => TextSize.set(1) },
        { name: "text large", glyph: Icons.textSize, keywords: "font size big", run: () => TextSize.set(1.15) },
        { name: "text extra large", glyph: Icons.textSize, keywords: "font size xl huge", run: () => TextSize.set(1.3) }
    ]

    function search(q) {
        return all.filter(a => q === "" || Apps.fuzzy(q, a.name + " " + a.keywords))
            .sort((a, b) => Apps.score(q, a.name) - Apps.score(q, b.name))
            .map(a => ({ kind: "action", title: a.name, sub: "action", glyph: a.glyph, confirm: a.confirm === true, run: a.run }));
    }
}
