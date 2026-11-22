import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "vol"

    Mono { text: "sound"; color: Colors.fgMuted }
    Slider {
        Layout.fillWidth: true
        icon: Audio.muted ? Icons.volumeOff : Icons.volume
        value: Audio.ready ? Audio.volume / 100 : 0
        label: Audio.ready ? (Audio.muted ? "muted" : Audio.volume + "%") : "--"
        onMoved: v => Audio.setVolume(v)
    }
    MonoButton {
        text: Audio.muted ? "unmute" : "mute"
        color: Colors.accent
        onClicked: Audio.toggleMute()
    }
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "output"; color: Colors.fgMuted }
    Repeater {
        model: Audio.sinks
        MonoButton {
            required property var modelData
            Layout.fillWidth: true
            elide: Text.ElideRight
            readonly property bool current: modelData === Audio.sink
            text: (current ? "> " : "  ") + Audio.label(modelData)
            color: current ? Colors.accent : Colors.fg
            onClicked: Audio.setSink(modelData)
        }
    }
}
