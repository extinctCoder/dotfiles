pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness via brightnessctl. The brightness keys call
// `qs ipc call brightness refresh` after changing it, so the island reacts.
Singleton {
    id: root
    property int percent: -1
    signal brightnessEvent()

    function refresh() { read.running = true; }
    function set(p) {
        writer.command = ["brightnessctl", "set", Math.max(1, Math.min(100, Math.round(p))) + "%"];
        writer.running = true;
    }

    Process {
        id: read
        command: ["brightnessctl", "-m"] // device,class,current,percent%,max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                const p = parseInt(f[3]);
                if (!isNaN(p)) {
                    const changed = p !== root.percent && root.percent !== -1;
                    root.percent = p;
                    if (changed) root.brightnessEvent();
                }
            }
        }
    }
    Process { id: writer; onExited: root.refresh() }
    Component.onCompleted: refresh()

    IpcHandler {
        target: "brightness"
        function refresh(): void { root.refresh(); }
    }
}
