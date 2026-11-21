pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property real fontScale: 1.33 // Quickshell sizes in pixels, Ghostty/GTK in points (1pt = 1.33px)
    readonly property real spacingScale: 1
    readonly property real animScale: 1

    readonly property string font: "FiraCode Nerd Font"
    readonly property int fontSm: Math.round(11 * fontScale)
    readonly property int fontMd: Math.round(12 * fontScale)
    readonly property int fontLg: Math.round(14 * fontScale)
    readonly property int fontXl: Math.round(28 * fontScale)

    readonly property int gap: Math.round(4 * spacingScale)
    readonly property int pad: Math.round(8 * spacingScale)
    readonly property int padLg: Math.round(16 * spacingScale)

    readonly property int radius: 0
    readonly property int border: 1
    readonly property real panelOpacity: 0.85
    readonly property int anim: Math.round(120 * animScale)

    readonly property int barHeight: Math.round(26 * fontScale)
    readonly property int rowHeight: Math.round(24 * fontScale)
}
