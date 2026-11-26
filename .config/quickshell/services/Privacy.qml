pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// What is recording right now, from PipeWire streams:
// an audio input stream = microphone in use; a video stream = camera or screen capture.
// Streams that record an output's monitor (stream.capture.sink = true: what the
// speakers play) never touch the microphone and don't count: cava, the lyrics
// listener (recognizing songs by ear), screen recorders' system audio.
Singleton {
    readonly property var nodes: Array.from(Pipewire.nodes.values)
    function listensToOutput(n) {
        const p = n.properties || {};
        return p["stream.capture.sink"] === "true" || p["stream.capture.sink"] === true
            || /cava|lyrics-listener/i.test(n.name); // also by name, in case the property isn't visible
    }
    readonly property var micApps: nodes.filter(n => n.type === PwNodeType.AudioInStream && !listensToOutput(n))
        .map(n => n.name || "unknown")
    readonly property var videoApps: nodes.filter(n => n.isStream && (n.type & PwNodeType.Video))
        .map(n => n.name || "unknown")
    readonly property bool active: micApps.length > 0 || videoApps.length > 0
}
