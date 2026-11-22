pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Battery level history for the desktop curve: the real level is appended to
// ~/.local/state/battery-history every 5 minutes ("unix-seconds percent charging").
// The curve shows the last 6 hours; it fills in over time.
Singleton {
    id: root
    readonly property string file: Quickshell.env("HOME") + "/.local/state/battery-history"
    property var points: [] // [{ t, p, c }] last 6 h, oldest first

    function load(text) {
        const since = Date.now() / 1000 - 6 * 3600;
        root.points = text.split("\n").map(l => l.trim().split(" ")).filter(f => f.length === 3 && Number(f[0]) >= since)
            .map(f => ({ t: Number(f[0]), p: Number(f[1]), c: f[2] === "1" }));
    }
    function record() {
        if (!Battery.present) return;
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && echo "$2 $3 $4" >> "$1" && tail -n 2000 "$1" > "$1.tmp" && mv "$1.tmp" "$1"',
            "sh", root.file, String(Math.round(Date.now() / 1000)), String(Battery.percent), Battery.charging ? "1" : "0"];
        writer.running = true;
    }

    FileView {
        id: view
        path: root.file
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text())
    }
    Process { id: writer }
    Timer { interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.record() }
}
