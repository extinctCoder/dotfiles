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

    signal volumeEvent() // the island listens to this

    // output devices (speakers, headphones, HDMI...)
    readonly property var sinks: Array.from(Pipewire.nodes.values).filter(n => n.isSink && !n.isStream && n.audio)

    function setVolume(v) { if (root.audio) root.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleMute() { if (root.audio) root.audio.muted = !root.audio.muted; }
    function setSink(n) { Pipewire.preferredDefaultAudioSink = n; }
    function label(n) { return n.nickname || n.description || n.name; }

    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.audio
        function onVolumeChanged() { root.volumeEvent(); }
        function onMutedChanged() { root.volumeEvent(); }
    }
}
