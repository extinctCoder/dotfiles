pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// File search in your home folder with fd, for the launcher. Debounced: runs
// 200 ms after typing stops. Skips .git, caches and node_modules.
Singleton {
    id: root
    property string query: ""
    property var results: [] // launcher rows
    readonly property string home: Quickshell.env("HOME")

    onQueryChanged: { if (query.length < 2) results = []; else debounce.restart(); }

    Timer { id: debounce; interval: 200; onTriggered: { finder.running = false; finder.running = true; } }

    Process {
        id: finder
        command: ["fd", "--type", "f", "--max-results", "20", "--fixed-strings", "--hidden",
            "--exclude", ".git", "--exclude", ".cache", "--exclude", "node_modules",
            "--", root.query, root.home]
        stdout: StdioCollector {
            onStreamFinished: root.results = text.split("\n").filter(l => l).map(path => ({
                kind: "file",
                title: path.split("/").pop(),
                sub: path.replace(root.home, "~"),
                glyph: Icons.file,
                run: () => Quickshell.execDetached(["xdg-open", path])
            }))
        }
    }
}
