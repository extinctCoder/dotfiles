pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Live audio spectrum from cava (what is playing right now, through PipeWire).
// Runs only while something plays; otherwise bars are empty (flat).
Singleton {
    id: root
    property var bars: [] // 72 values, 0..1, low to high frequencies
    // the same spectrum split into bands, and a beat on each real bass hit
    property real bass: 0
    property real mid: 0
    property real high: 0
    property real bassAvg: 0
    property real lastBeat: 0
    signal beat()

    function analyse(b) {
        root.bars = b;
        if (b.length === 0) return;
        const avg = (s, e) => { let t = 0; for (let i = s; i < e; i++) t += b[i] || 0; return t / (e - s); };
        root.bass = avg(0, 8);
        root.mid = avg(8, 30);
        root.high = avg(30, b.length);
        const now = Date.now() / 1000;
        // a beat: bass jumps well above its recent average (and not twice within 0.28 s)
        if (root.bass > 0.25 && root.bass > root.bassAvg * 1.35 && now - root.lastBeat > 0.28) {
            root.lastBeat = now;
            root.beat();
        }
        root.bassAvg = root.bassAvg * 0.92 + root.bass * 0.08;
    }

    Process {
        running: Media.active
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/quickshell.conf"]
        stdout: SplitParser {
            onRead: line => root.analyse(line.split(";").filter(v => v !== "").map(v => Number(v) / 100))
        }
        onRunningChanged: if (!running) { root.bars = []; root.bass = 0; root.mid = 0; root.high = 0; }
    }
}
