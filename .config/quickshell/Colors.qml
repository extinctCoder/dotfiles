pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "#11140e"
    readonly property color panel: Qt.rgba(bg.r, bg.g, bg.b, Style.panelOpacity)
    readonly property color raised: "#282b24"
    readonly property color fg: "#e1e3d9"
    readonly property color fgMuted: "#c4c8bb"
    readonly property color accent: "#acd28e"
    readonly property color accentFg: "#1a3705"
    readonly property color border: "#44483e"
    readonly property color alert: "#ffb4ab"
    readonly property color ok: "#acd28f"
    readonly property string wallpaper: "/home/extinctcoder/dotfiles/Pictures/wallpapers/derrick-cooper.jpg"
}
