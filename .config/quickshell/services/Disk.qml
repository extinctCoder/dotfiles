pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Drives (local filesystems from df, each device once) and disk activity
// (bytes read/written per second from /proc/diskstats, whole disks only).
Singleton {
    id: root
    property var drives: []      // [{ label, used, size }], bytes
    property real readRate: -1   // bytes per second
    property real writeRate: -1
    property var readHistory: [] // last 40 samples
    property var writeHistory: []
    property var prev: null
    property real prevTime: 0

    Process {
        id: df
        command: ["df", "-B1", "--output=source,target,size,used", "-x", "tmpfs", "-x", "devtmpfs",
            "-x", "efivarfs", "-x", "squashfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}, out = [];
                for (const l of text.trim().split("\n").slice(1)) {
                    const f = l.trim().split(/\s+/);
                    // local disks only: network shares (SMB, NFS, fuse) are not drives
                    if (f.length < 4 || !f[0].startsWith("/dev/") || seen[f[0]]) continue;
                    seen[f[0]] = true;
                    out.push({ label: f[1] === "/" ? "root" : f[1].split("/").pop(), used: Number(f[3]), size: Number(f[2]) });
                }
                root.drives = out.slice(0, 3);
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: df.running = true }

    Process {
        id: stats
        command: ["cat", "/proc/diskstats"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now() / 1000;
                let r = 0, w = 0;
                for (const l of text.split("\n")) {
                    const f = l.trim().split(/\s+/);
                    // whole disks only (not partitions); fields: 5 = sectors read, 9 = sectors written
                    if (/^(nvme\d+n\d+|sd[a-z]+|vd[a-z]+|mmcblk\d+)$/.test(f[2])) { r += Number(f[5]) * 512; w += Number(f[9]) * 512; }
                }
                if (root.prev && now > root.prevTime) {
                    root.readRate = Math.max(0, (r - root.prev.r) / (now - root.prevTime));
                    root.writeRate = Math.max(0, (w - root.prev.w) / (now - root.prevTime));
                    root.readHistory = root.readHistory.concat([root.readRate]).slice(-40);
                    root.writeHistory = root.writeHistory.concat([root.writeRate]).slice(-40);
                }
                root.prev = { r: r, w: w };
                root.prevTime = now;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: stats.running = true }
}
