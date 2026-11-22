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
    property real lastBeat: 0
    property var prevBars: []
    property var fluxHistory: [] // last ~1.5 s of onset strength
    signal beat()

    function analyse(b) {
        root.bars = b;
        if (b.length === 0) return;
        const avg = (s, e) => { let t = 0; for (let i = s; i < e; i++) t += b[i] || 0; return t / (e - s); };
        root.bass = avg(0, 12);
        root.mid = avg(12, 36);
        root.high = avg(36, b.length);
        // Beats by spectral flux: how much the low half of the spectrum (~50-500 Hz,
        // kick and bass, wherever a song puts them) suddenly grew since the last frame.
        // A beat is a jump well above the recent average, so it adapts to quiet and loud songs.
        const n = Math.min(32, b.length);
        let flux = 0;
        let weight = 0;
        for (let i = 0; i < n; i++) {
            const w = i < 20 ? 1.5 : 1; // the kick region counts more
            flux += w * Math.max(0, b[i] - (root.prevBars[i] || 0));
            weight += w;
        }
        flux /= weight;
        root.prevBars = b;
        const h = root.fluxHistory;
        const mean = h.length ? h.reduce((a, x) => a + x, 0) / h.length : 0;
        const sd = h.length ? Math.sqrt(h.reduce((a, x) => a + (x - mean) * (x - mean), 0) / h.length) : 0;
        const now = Date.now() / 1000;
        if (h.length >= 10 && flux > 0.015 && flux > mean + 1.2 * sd && now - root.lastBeat > 0.28) {
            root.lastBeat = now;
            root.beat();
        }
        root.fluxHistory = h.slice(-44).concat([flux]);
    }

    Process {
        running: Media.active
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/quickshell.conf"]
        stdout: SplitParser {
            onRead: line => root.analyse(line.split(";").filter(v => v !== "").map(v => Number(v) / 100))
        }
        onRunningChanged: if (!running) { root.bars = []; root.bass = 0; root.mid = 0; root.high = 0; root.prevBars = []; root.fluxHistory = []; }
    }
}
