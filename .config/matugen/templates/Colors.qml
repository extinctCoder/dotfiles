pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "{{colors.surface.default.hex}}"
    readonly property color panel: Qt.rgba(bg.r, bg.g, bg.b, Style.panelOpacity)
    readonly property color raised: "{{colors.surface_container_high.default.hex}}"
    readonly property color fg: "{{colors.on_surface.default.hex}}"
    readonly property color fgMuted: "{{colors.on_surface_variant.default.hex}}"
    readonly property color accent: "{{colors.primary.default.hex}}"
    readonly property color accentFg: "{{colors.on_primary.default.hex}}"
    readonly property color border: "{{colors.outline_variant.default.hex}}"
    readonly property color alert: "{{colors.error.default.hex}}"
    readonly property color ok: "{{colors.green.default.hex}}"
    readonly property string wallpaper: "{{image}}"
}
