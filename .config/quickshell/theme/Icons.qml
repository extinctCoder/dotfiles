pragma Singleton
import Quickshell
import QtQuick

// Nerd Font glyphs (Material Design set), by codepoint from the official
// Nerd Fonts glyph list, so no symbol is typed from memory.
Singleton {
    readonly property string wifi: String.fromCodePoint(0xf05a9)
    readonly property string wifiOff: String.fromCodePoint(0xf05aa)
    readonly property string cpu: String.fromCodePoint(0xf0ee0) // md-cpu_64_bit
    readonly property string mem: String.fromCodePoint(0xefc5)  // fa-memory (RAM stick)
    readonly property string volume: String.fromCodePoint(0xf057e)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)
    readonly property string battery: String.fromCodePoint(0xf0079)
    readonly property string charging: String.fromCodePoint(0xf0084)
    readonly property string bell: String.fromCodePoint(0xf009a)
    readonly property string bellBadge: String.fromCodePoint(0xf116b)
    readonly property string bellOff: String.fromCodePoint(0xf009b)
    readonly property string mic: String.fromCodePoint(0xf036c)
    readonly property string video: String.fromCodePoint(0xf0567)
    readonly property string coffee: String.fromCodePoint(0xf0176)
    readonly property string night: String.fromCodePoint(0xf0594)
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string bluetoothOff: String.fromCodePoint(0xf00b2)
    readonly property string brightness: String.fromCodePoint(0xf00df)
    readonly property string temp: String.fromCodePoint(0xf050f)
    readonly property string down: String.fromCodePoint(0xf01da)
    readonly property string up: String.fromCodePoint(0xf0552)
    readonly property string music: String.fromCodePoint(0xf0387)
    readonly property string calendar: String.fromCodePoint(0xf00ed)
    readonly property string power: String.fromCodePoint(0xf0425)
}
