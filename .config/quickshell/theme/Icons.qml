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

    // launcher rows
    readonly property string file: String.fromCodePoint(0xf0214)
    readonly property string web: String.fromCodePoint(0xf059f)
    readonly property string calc: String.fromCodePoint(0xf00ec)
    readonly property string action: String.fromCodePoint(0xf140b)
    readonly property string image: String.fromCodePoint(0xf02e9)
    readonly property string lock: String.fromCodePoint(0xf033e)
    readonly property string logout: String.fromCodePoint(0xf0343)
    readonly property string sleep: String.fromCodePoint(0xf04b2)
    readonly property string restart: String.fromCodePoint(0xf0709)
    readonly property string screenshot: String.fromCodePoint(0xf0e51)
    readonly property string clipboard: String.fromCodePoint(0xf014d)
    readonly property string keyboard: String.fromCodePoint(0xf030c)
    readonly property string tune: String.fromCodePoint(0xf062e)
    readonly property string textSize: String.fromCodePoint(0xf027f)
    readonly property string shuffle: String.fromCodePoint(0xf049f)
    readonly property string grid: String.fromCodePoint(0xf0570)
    readonly property string bookmark: String.fromCodePoint(0xf00c0)
    readonly property string history: String.fromCodePoint(0xf02da)
    readonly property string youtube: String.fromCodePoint(0xf05c3)
    readonly property string play: String.fromCodePoint(0xf040c)
}
