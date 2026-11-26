pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The busiest processes right now, for the dashboard's system tab. Only runs
// while something asks for it (watching = true). Uses top's 2nd sample: usage
// right now (its 1st, like ps, is the average since each process started).
Singleton {
    id: root
    property bool watching: false
    property var top: [] // [{ name, cpu, mem }], busiest first

    Process {
        id: ps
        command: ["sh", "-c", "top -b -n 2 -d 0.5 -o %CPU -w 512 | awk '/^ *PID/ {n++; next} n == 2 && $12 != \"top\" {print $12, $9, $6}' | head -n 6"]
        stdout: StdioCollector {
            onStreamFinished: root.top = text.trim().split("\n").filter(l => l).map(l => {
                const f = l.trim().split(/\s+/);
                const res = f.pop(), cpu = f.pop();
                // top's RES column: KiB, or with a unit suffix (m, g)
                const kib = /g$/i.test(res) ? parseFloat(res) * 1048576 : /m$/i.test(res) ? parseFloat(res) * 1024 : parseFloat(res);
                return { name: f.join(" "), cpu: Number(cpu), mem: kib * 1024 };
            })
        }
    }
    Timer { interval: 2000; running: root.watching; repeat: true; triggeredOnStart: true; onTriggered: ps.running = true }
}
