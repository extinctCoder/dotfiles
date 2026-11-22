pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Extra sensors for the living core, read every 2 s without root.
//   gpu       Intel iGPU busy share, 0..1 (-1 = no Intel GPU found)
//             i915/xe have no unprivileged busy counter, so this is the share of
//             time the GPU stays out of its RC6 sleep: 1 - delta(rc6 ms) / delta(wall ms).
//             It reads a little high at idle (the GPU wakes for more than drawing).
//             A frozen counter means either fully busy (clock above minimum) or
//             fully asleep. A runtime-suspended GPU is not read (reading wakes it).
//   nvmeTemp  NVMe drive temperature, °C (-1 = none), hwmon "nvme" temp1 (Composite)
Singleton {
    id: root
    property real gpu: -1
    property real nvmeTemp: -1
    property var prev: null

    Process {
        id: reader
        command: ["sh", "-c", `
            for c in /sys/class/drm/card[0-9]*; do
                drv=$(basename "$(readlink -f "$c/device/driver" 2>/dev/null)")
                [ "$drv" = i915 ] || [ "$drv" = xe ] || continue
                st=$(cat "$c/device/power/runtime_status" 2>/dev/null)
                if [ "$st" = suspended ]; then echo "GPU suspended"; break; fi
                rc6=$(cat "$c/gt/gt0/rc6_residency_ms" 2>/dev/null || cat "$c/power/rc6_residency_ms" 2>/dev/null || cat "$c/device/tile0/gt0/gtidle/idle_residency_ms" 2>/dev/null)
                act=$(cat "$c/gt/gt0/rps_act_freq_mhz" 2>/dev/null || cat "$c/gt_act_freq_mhz" 2>/dev/null || echo 0)
                min=$(cat "$c/gt/gt0/rps_min_freq_mhz" 2>/dev/null || cat "$c/gt_min_freq_mhz" 2>/dev/null || echo 0)
                [ -n "$rc6" ] && echo "GPU active $rc6 $act $min"
                break
            done
            for h in /sys/class/hwmon/hwmon*; do
                [ "$(cat "$h/name" 2>/dev/null)" = nvme ] && echo "NVME $(cat "$h/temp1_input" 2>/dev/null)" && break
            done
            true`]
        stdout: StdioCollector { onStreamFinished: root.parse(text, Date.now()) }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: reader.running = true }

    function parse(text, now) {
        let gpuSeen = false;
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "NVME" && f[1]) root.nvmeTemp = Number(f[1]) / 1000;
            if (f[0] !== "GPU") continue;
            gpuSeen = true;
            if (f[1] === "suspended") { root.gpu = 0; root.prev = null; continue; } // asleep: idle, start over
            const rc6 = Number(f[2]), act = Number(f[3]), min = Number(f[4]);
            if (root.prev && now > root.prev.t) {
                const dRc6 = rc6 - root.prev.rc6, dWall = now - root.prev.t;
                if (dRc6 < 0) { root.prev = null; continue; }               // counter reset
                if (dRc6 === 0) root.gpu = act > min ? 1 : 0;               // frozen: fully busy, or powered down
                else root.gpu = Math.max(0, Math.min(1, 1 - dRc6 / dWall));
            }
            root.prev = { rc6: rc6, t: now };
        }
        if (!gpuSeen) root.gpu = -1;
    }
}
