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
    property real bass: 0   // 20-250 Hz
    property real mid: 0    // 250 Hz - 4 kHz
    property real high: 0   // 4-20 kHz
    property real lastBeat: 0
    property var prevBars: []
    property var fluxHistory: [] // last ~1.5 s of onset strength

    // cava's bar frequencies (keep in sync with ~/.config/cava/quickshell.conf):
    // bars on a log scale, same formula as cava (cavacore.c), so bands are picked
    // by real frequency and stay right if the range or bar count changes.
    readonly property int barCount: 72
    readonly property real lowHz: 20
    readonly property real highHz: 20000
    readonly property var barHz: {
        const n = barCount, c = Math.log10(lowHz / highHz) / (1 / (n + 1) - 1);
        return Array.from({ length: n }, (_, i) => highHz * Math.pow(10, c * (-1 + (i + 1) / (n + 1))));
    }
    function barsBelow(hz) { const i = barHz.findIndex(f => f >= hz); return i < 0 ? barCount : i; }
    readonly property int bassEnd: barsBelow(250)
    readonly property int midEnd: barsBelow(4000)
    readonly property int beatEnd: barsBelow(500)
    readonly property int kickStart: barsBelow(40)
    readonly property int kickEnd: barsBelow(200)
    signal beat()

    function analyse(b) {
        root.bars = b;
        if (b.length === 0) return;
        const avg = (s, e) => { let t = 0; for (let i = s; i < e; i++) t += b[i] || 0; return t / (e - s); };
        root.bass = avg(0, root.bassEnd);
        root.mid = avg(root.bassEnd, root.midEnd);
        root.high = avg(root.midEnd, b.length);
        // Beats by spectral flux: how much 20-500 Hz (kick and bass, wherever a song
        // puts them) suddenly grew since the last frame; the kick region (40-200 Hz) counts more.
        // A beat is a jump well above the recent average, so it adapts to quiet and loud songs.
        const n = Math.min(root.beatEnd, b.length);
        let flux = 0;
        let weight = 0;
        for (let i = 0; i < n; i++) {
            const w = i >= root.kickStart && i < root.kickEnd ? 2 : 1;
            flux += w * Math.max(0, b[i] - (root.prevBars[i] || 0));
            weight += w;
        }
        flux /= weight;
        root.prevBars = b;
        const h = root.fluxHistory;
        const mean = h.length ? h.reduce((a, x) => a + x, 0) / h.length : 0;
        const sd = h.length ? Math.sqrt(h.reduce((a, x) => a + (x - mean) * (x - mean), 0) / h.length) : 0;
        const now = Date.now() / 1000;
        if (h.length >= 10 && flux > 0.015 && flux > mean + 0.8 * sd && now - root.lastBeat > 0.28) {
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
