pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history from cliphist.
Singleton {
    id: root
    property var items: [] // raw cliphist lines: "id<TAB>preview"

    function load() { lister.running = true; }
    function search(query) { return items.filter(c => Apps.fuzzy(query, c)).slice(0, 50); }
    function label(line) { return line.split("\t").slice(1).join(" "); }
    function copy(line) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", line]);
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.items = text.split("\n").filter(l => l.length > 0)
        }
    }
}
