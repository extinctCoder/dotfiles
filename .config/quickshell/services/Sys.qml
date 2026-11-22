pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU, memory, network and temperature, read from the kernel every 2 s.
// Every value is -1 until real data exists; the UI shows "--" for it.
Singleton {
    id: root
    property real cpu: -1            // total usage, 0..100
    property var cores: []           // per-core usage, 0..100
    property var coreHistory: []     // last 30 samples of `cores` (oldest first)
    property real memUsed: -1        // bytes
    property real memTotal: -1
    property real swapUsed: -1
    property real swapTotal: -1
    property real rxRate: -1         // bytes per second, all interfaces except lo
    property real txRate: -1
    property real temp: -1           // °C, CPU package
    property var rxHistory: []       // last 60 samples, bytes per second
    property var txHistory: []
    property real uptime: -1         // seconds since boot
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal * 100 : -1

    property var prevCpu: null
    property var prevNet: null
    property real prevTime: 0
    property string tempFile: ""

    function pct(v) { return v < 0 ? "--" : Math.round(v) + "%"; }
    function rate(b) {
        if (b < 0) return "--";
        if (b >= 1048576) return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024) return Math.round(b / 1024) + "K";
        return Math.round(b) + "B";
    }
    function duration(s) {
        if (s < 0) return "--";
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d ? d + "d " : "") + (d || h ? h + "h " : "") + m + "m";
    }
    function gib(b) {
        if (b < 0) return "--";
        const g = b / 1073741824;
        return (g >= 10 ? Math.round(g) : g.toFixed(1)) + "G";
    }

    // find the CPU temperature sensor once (Intel coretemp, AMD k10temp/zenpower, or the package thermal zone)
    Process {
        running: true
        command: ["sh", "-c",
            'for d in /sys/class/hwmon/hwmon*; do n=$(cat "$d/name" 2>/dev/null); '
            + 'case "$n" in coretemp|k10temp|zenpower) echo "$d/temp1_input"; exit;; esac; done; '
            + 'for z in /sys/class/thermal/thermal_zone*; do [ "$(cat "$z/type")" = x86_pkg_temp ] && echo "$z/temp" && exit; done']
        stdout: StdioCollector { onStreamFinished: root.tempFile = text.trim() }
    }

    Process {
        id: sample
        command: ["sh", "-c", 'cat /proc/stat /proc/meminfo /proc/net/dev; echo "UP $(cut -d " " -f 1 /proc/uptime)"; [ -n "$1" ] && echo "TEMP $(cat "$1" 2>/dev/null)"',
            "sh", root.tempFile]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: sample.running = true
    }

    function parse(text) {
        const now = Date.now() / 1000;
        const cpus = [];
        const mem = {};
        let rx = 0, tx = 0, t = -1;
        for (const line of text.split("\n")) {
            if (/^cpu\d*\s/.test(line)) {
                const v = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = v[3] + (v[4] || 0);
                cpus.push({ idle: idle, total: v.reduce((a, b) => a + b, 0) });
                continue;
            }
            let m = line.match(/^(\w+(?:\(\w+\))?):\s+(\d+) kB/);
            if (m) { mem[m[1]] = Number(m[2]) * 1024; continue; }
            m = line.match(/^\s*([\w.-]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/);
            if (m && m[1] !== "lo") { rx += Number(m[2]); tx += Number(m[3]); continue; }
            m = line.match(/^TEMP (\d+)/);
            if (m) t = Number(m[1]) / 1000;
            m = line.match(/^UP ([\d.]+)/);
            if (m) root.uptime = Number(m[1]);
        }
        if (root.prevCpu && root.prevCpu.length === cpus.length) {
            const usage = cpus.map((c, i) => {
                const dt = c.total - root.prevCpu[i].total;
                const di = c.idle - root.prevCpu[i].idle;
                return dt > 0 ? Math.max(0, Math.min(100, (1 - di / dt) * 100)) : 0;
            });
            root.cpu = usage[0];
            root.cores = usage.slice(1);
            root.coreHistory = root.coreHistory.concat([root.cores]).slice(-30);
        }
        root.prevCpu = cpus;
        if (mem.MemTotal) {
            root.memTotal = mem.MemTotal;
            root.memUsed = mem.MemTotal - (mem.MemAvailable || 0);
            root.swapTotal = mem.SwapTotal || 0;
            root.swapUsed = (mem.SwapTotal || 0) - (mem.SwapFree || 0);
        }
        if (root.prevNet && now > root.prevTime) {
            root.rxRate = Math.max(0, (rx - root.prevNet.rx) / (now - root.prevTime));
            root.txRate = Math.max(0, (tx - root.prevNet.tx) / (now - root.prevTime));
            root.rxHistory = root.rxHistory.concat([root.rxRate]).slice(-60);
            root.txHistory = root.txHistory.concat([root.txRate]).slice(-60);
        }
        root.prevNet = { rx: rx, tx: tx };
        root.prevTime = now;
        root.temp = t;
    }
}
