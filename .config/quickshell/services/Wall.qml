pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs

// The wallpaper: current path, the folder's images, and setting a new one
// (which also recolors everything through matugen).
Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/wallpaper"
    property string path: Colors.wallpaper // replaced by the state file once loaded
    property var files: []

    // --source-color-index 0: take the most dominant color. Without it, matugen 4
    // asks interactively when an image has several candidates and, with no
    // terminal, exits without writing colors. Failures show a notification.
    readonly property string script:
        'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2" && '
        + '{ matugen image -m dark --source-color-index 0 "$1" '
        + '|| notify-send -a wallpaper -u critical "colors failed" "run: matugen image -m dark --source-color-index 0 $1"; }'

    function set(p) {
        Quickshell.execDetached(["sh", "-c", script, "sh", p, stateFile]);
    }
    function next() {
        Quickshell.execDetached(["sh", "-c",
            'f=$(find -L "$1" -type f | grep -iE "[.](jpe?g|png|webp)$" | shuf -n 1) && set -- "$f" "$2" && ' + script,
            "sh", dir, stateFile]);
    }
    function scan() { lister.running = true; } // -L: stowed wallpapers are symlinks

    FileView {
        path: root.stateFile
        printErrors: false // missing until the first wallpaper is set
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = text().trim();
            if (p !== "") root.path = p;
        }
    }

    Process {
        id: lister
        command: ["sh", "-c", 'find -L "$1" -maxdepth 1 -type f | grep -iE "[.](jpe?g|png|webp)$" | sort', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { root.set(path); }
        function next(): void { root.next(); }
        function get(): string { return root.path; }
    }
}
