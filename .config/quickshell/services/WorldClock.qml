pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Times from the system time-zone database (`date` with TZ), so daylight saving
// and Morocco's Ramadan changes are always right. Updated every 30 s.
Singleton {
    id: root
    readonly property var zones: [
        { name: "miami", tz: "America/New_York" },
        { name: "new delhi", tz: "Asia/Kolkata" },
        { name: "casablanca", tz: "Africa/Casablanca" },
        { name: "bangkok", tz: "Asia/Bangkok" }
    ]
    property var times: [] // [{ name, time: "23:21", diff: "-11h" }]

    function minutes(z) { // "+0600" -> 360
        const s = z[0] === "-" ? -1 : 1;
        return s * (Number(z.slice(1, 3)) * 60 + Number(z.slice(3, 5)));
    }
    function diffText(m) {
        if (m === 0) return "0";
        const sign = m < 0 ? "-" : "+";
        const a = Math.abs(m), h = Math.floor(a / 60), mm = a % 60;
        return sign + (h ? h + "h" : "") + (mm ? mm + "m" : "");
    }

    Process {
        id: read
        command: ["sh", "-c", 'date "+%H:%M %z"; for z in "$@"; do TZ="$z" date "+%H:%M %z"; done', "sh"]
            .concat(root.zones.map(z => z.tz))
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n").map(s => s.split(" "));
                if (l.length !== root.zones.length + 1) return;
                const local = root.minutes(l[0][1]);
                root.times = root.zones.map((z, i) => ({
                    name: z.name, time: l[i + 1][0], diff: root.diffText(root.minutes(l[i + 1][1]) - local)
                }));
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: read.running = true }
}
