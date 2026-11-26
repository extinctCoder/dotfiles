pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which apps have a single-color icon in YAMIS-matugen (icons/install.sh).
// find() returns the icon's file for the first name it knows, or "".
Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/icons/YAMIS-matugen/apps/scalable/"
    property var names: ({})

    function find(candidates) {
        for (const c of candidates) {
            if (!c) continue;
            for (const n of [c, c.toLowerCase()]) if (names[n]) return "file://" + dir + n + ".svg";
        }
        return "";
    }
    function refresh() { lister.running = true; }

    Process {
        id: lister
        command: ["sh", "-c", 'ls "$1" 2>/dev/null', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = {};
                for (const f of text.split("\n")) if (f.endsWith(".svg")) n[f.slice(0, -4)] = true;
                root.names = n;
            }
        }
    }
    Component.onCompleted: refresh()
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refresh() } // picks up a later install
}
