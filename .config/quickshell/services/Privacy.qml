pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// What is recording right now, from PipeWire streams:
// an audio input stream = microphone in use; a video stream = camera or screen capture.
Singleton {
    readonly property var nodes: Array.from(Pipewire.nodes.values)
    // cava (the desktop visualizer) listens to speaker output, not the mic: never count it
    function isMine(n) { return /cava/i.test(n.name); }
    readonly property var micApps: nodes.filter(n => n.type === PwNodeType.AudioInStream && !isMine(n))
        .map(n => n.name || "unknown")
    readonly property var videoApps: nodes.filter(n => n.isStream && (n.type & PwNodeType.Video))
        .map(n => n.name || "unknown")
    readonly property bool active: micApps.length > 0 || videoApps.length > 0
}
