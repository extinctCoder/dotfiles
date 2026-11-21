pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The default speaker: volume, mute, and an event whenever either changes.
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property bool ready: audio !== null
    readonly property int volume: Math.round((audio?.volume ?? 0) * 100)
    readonly property bool muted: audio?.muted ?? false

    signal volumeEvent() // the volume popup listens to this

    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.audio
        function onVolumeChanged() { root.volumeEvent(); }
        function onMutedChanged() { root.volumeEvent(); }
    }
}
