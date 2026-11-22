pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Night light through hyprsunset's IPC (via hyprctl). identity = normal colors.
Singleton {
    id: root
    property bool on: false

    function refresh() { query.running = true; }
    function toggle() {
        setter.command = root.on ? ["hyprctl", "hyprsunset", "identity", "true"]
                                 : ["hyprctl", "hyprsunset", "temperature", "4500"];
        setter.running = true;
    }

    Process {
        id: query
        command: ["hyprctl", "hyprsunset", "identity"]
        stdout: StdioCollector { onStreamFinished: root.on = text.trim() === "false" }
    }
    Process { id: setter; onExited: root.refresh() }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
