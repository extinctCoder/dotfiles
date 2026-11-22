import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

// The living core: one creature fed by live data.
//   heart    a knot of particles; its beat sends waves through the body
//   body     subsystem bands (compute, memory, storage, network), calm or chaotic
//   skin     wraps the body; grows fast, relaxes slowly (memory); ripples, dents, trembles
//   eating   download in through the skin, upload out; charging feeds the heart
//   hunger   low battery weakens the heart; fever (temperature) speeds it up
//   presence away or locked: the heart weakens, the body loosens / collapses
//   senses   mic or camera in use: the skin turns alert
// Signals: CPU (total + busiest core), Intel GPU, RAM, swap, disk read and write,
// network, CPU + NVMe temperature, battery, power draw, music, notifications,
// workspaces, idle, lock, mic/camera.
// Every motion comes from a real signal. Drawn on the GPU (shaders/), animated
// only while `running` (the desktop decides: not when windows cover it).
Item {
    id: core
    property bool running: true
    readonly property real unit: Math.min(width, height) / 430 // designed on a 560 square, drawn ~30% larger

    // ---------------- live signals, 0..1 ----------------
    function rateNorm(b) { return b > 0 ? Math.min(1, Math.log10(b / 1e4 + 1) / 4) : 0; } // 10 kB/s .. 100 MB/s
    readonly property real cpu: Math.max(0, Sys.cpu) / 100
    readonly property real ram: Sys.memPercent > 0 ? Sys.memPercent / 100 : 0
    readonly property real swap: Sys.swapTotal > 0 ? Math.max(0, Sys.swapUsed) / Sys.swapTotal : 0
    readonly property real diskRead: rateNorm(Disk.readRate)
    readonly property real diskWrite: rateNorm(Disk.writeRate)
    readonly property real disk: Math.max(diskRead, diskWrite)
    readonly property real maxCore: Sys.cores.length ? Math.max(...Sys.cores) / 100 : cpu // one pegged core is strain even if the total is low
    readonly property real gpu: Sensors.gpu > 0 ? Math.max(0, (Sensors.gpu - 0.12) / 0.88) : 0 // RC6 reads ~10% high at idle
    readonly property real power: Battery.present && Battery.discharging ? Math.min(1, Battery.watts / 35) : 0 // draw on battery
    readonly property bool watched: Privacy.active // mic or camera in use
    readonly property real rx: rateNorm(Sys.rxRate)
    readonly property real tx: rateNorm(Sys.txRate)
    readonly property real heat: Math.max(Sys.temp > 0 ? Math.min(1, Math.max(0, (Sys.temp - 40) / 50)) : 0, // CPU: 40 °C calm, 90 °C fever
        Sensors.nvmeTemp > 0 ? Math.min(1, Math.max(0, (Sensors.nvmeTemp - 45) / 30)) : 0)              // NVMe: 45 °C calm, 75 °C fever
    readonly property bool charging: Battery.present && Battery.charging
    readonly property real hunger: !Battery.present || charging ? 0 : Battery.percent < 15 ? 0.5 : Battery.percent < 30 ? 0.2 : 0
    readonly property bool unwell: Battery.present && !charging && Battery.percent < 10
    readonly property bool music: Media.active

    IdleMonitor { id: idle; timeout: 90 } // seconds without keyboard/mouse = away

    // ---------------- state ----------------
    property real t: 0
    property var bands: [
        { k: "compute", ax: [0.15, 1, 0.1], pa: [0.3, 0.2, 1], dir: -1 },
        { k: "memory", ax: [1, 0.35, 0.2], pa: [0, 1, 0.4], dir: 1 },
        { k: "storage", ax: [0.6, -0.5, 0.8], pa: [1, 0.2, -0.3], dir: -1 },
        { k: "network", ax: [-0.7, 0.4, 0.6], pa: [-0.2, 1, 0.5], dir: 1 }
    ].map(b => Object.assign(b, { ax: norm(b.ax), pa: norm(b.pa), load: 0, chaos: 0, phase: 0, rate: 0, reach: 70 }))
    property var waves: []          // [{ r, a }] heartbeat waves, at most 4
    property real strength: 1       // heart strength
    property real lock: 0           // 1 = collapsed into the heart
    property real glow: 0           // last beat's glow
    property real food: 0           // charge delivered to the heart
    property real touchAmt: 0
    property real touchWidth: 0.2
    property real flinchAt: -1
    property real nextBeat: 0
    property real heartPhase: 0
    property real awayFor: 0
    property real musicAmt: 0
    property real kick: 0

    // ---------------- vector helpers ----------------
    function norm(v) { const l = Math.hypot(v[0], v[1], v[2]) || 1; return [v[0] / l, v[1] / l, v[2] / l]; }
    function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
    function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
    function rotate(v, k, ang) { // Rodrigues: rotate v around unit axis k
        const c = Math.cos(ang), s = Math.sin(ang), kx = cross(k, v), kd = dot(k, v);
        return [0, 1, 2].map(i => v[i] * c + kx[i] * s + k[i] * kd * (1 - c));
    }
    function ease(rate, dt) { return 1 - Math.exp(-rate * dt); } // frame-rate independent smoothing

    function pulse(a) { const w = core.waves.slice(-3); w.push({ r: 12, a: a }); core.waves = w; core.glow = 1; }

    // ---------------- events ----------------
    Connections {
        target: Visualizer
        function onBeat() { if (core.running && core.music) { core.kick = 1; core.pulse(1.0 * Math.max(0.3, core.strength)); } }
    }
    Connections {
        target: Notifs
        function onNotified(text, critical) { if (!Notifs.dnd) { core.touchAmt = 1; core.touchWidth = 0.15; core.flinchAt = core.t + 0.35; } }
    }
    Connections {
        target: Hypr
        function onFocusedIdChanged() { core.pulse(0.5); }
    }
    Connections {
        target: Session
        function onLockedChanged() { if (Session.locked) core.lock = 1; else core.pulse(2.0); } // wake with a strong beat
    }
    Connections {
        target: idle
        function onIsIdleChanged() { if (!idle.isIdle) core.pulse(2.0); }
    }

    // ~30 updates/s. A Timer, not FrameAnimation: a running FrameAnimation keeps
    // the whole desktop window redrawing at full refresh rate even when only every
    // other frame changes (measured: 92 vs 32 frames drawn per second).
    property real lastTick: 0
    Timer {
        interval: 33
        repeat: true
        running: core.running && core.visible
        onRunningChanged: core.lastTick = Date.now()
        onTriggered: {
            const now = Date.now();
            core.step(Math.min(0.1, (now - core.lastTick) / 1000));
            core.lastTick = now;
        }
    }

    function step(dt) {
        t += dt;
        // bands: load, chaos, motion
        const targets = { compute: Math.max(cpu, gpu * 0.9), memory: Math.min(1, Math.max(0, (ram - 0.1) / 0.9) + swap * 0.6), storage: disk, network: Math.max(rx, tx) };
        const chaosT = {
            compute: Math.max(Math.pow(cpu, 1.6), Math.pow(maxCore, 2) * 0.7, Math.pow(gpu, 1.6)) + heat * 0.3,
            memory: Math.pow(Math.max(0, ram - 0.6) / 0.4, 1.5) + swap,
            storage: Math.pow(diskWrite, 1.5) + Math.pow(diskRead, 1.5) * 0.5 + swap * 0.5, // writes strain more than reads
            network: Math.pow(Math.max(rx, tx), 1.8)
        };
        const looseness = 1 + (1 - Math.min(1, strength)) * 0.5;
        for (const b of bands) {
            b.load += (targets[b.k] - b.load) * ease(3, dt);
            b.chaos += (Math.min(1, chaosT[b.k] + heat * 0.15) - b.chaos) * ease(2.4, dt);
            b.rate = 0.27 * (0.3 + b.load * 2.6);
            b.phase += dt * b.rate * Math.min(1.2, strength) * (1 + b.chaos * 0.4);
            if (b.load > 0.005) b.ax = norm(rotate(b.ax, b.pa, b.dir * 60 * dt * (0.002 + b.load * 0.02) * (1 + b.chaos * 0.8) * Math.min(1, strength)));
            const reach = (30 + 40 + b.load * 75) * looseness * (1 - lock * 0.85);
            b.reach += (reach - b.reach) * (reach > b.reach ? ease(9, dt) : ease(0.36, dt)); // skin memory: grow fast, relax slowly
        }
        for (const b of bands) for (const o of bands) { // bands keep apart on the sphere
            if (o === b || b.load < 0.005 || o.load < 0.005) continue;
            const d = dot(b.ax, o.ax), near = Math.max(Math.abs(d) - 0.55, 0);
            if (near > 0) { const push = norm(cross(cross(o.ax, b.ax), b.ax)), sg = d > 0 ? 1 : -1; b.ax = norm(b.ax.map((x, i) => x - push[i] * near * 0.6 * dt * sg * (0.3 + b.load))); }
        }
        bandsChanged();

        // heart
        const energy = Math.min(1, 0.45 * cpu + 0.15 * gpu + 0.1 * ram + 0.1 * disk + 0.1 * Math.max(rx, tx) + 0.1 * power);
        awayFor = idle.isIdle ? awayFor + dt : 0;
        if (charging) food = Math.min(1, food + dt * 0.08); else food *= Math.pow(0.995, dt * 60);
        const target = (Session.locked ? 0.05 : idle.isIdle ? Math.max(0.25, 1 - awayFor / 18) : 1) * (1 - hunger) * (1 + food * 0.3);
        strength += (target - strength) * ease(2.4, dt);
        lock += ((Session.locked ? 1 : 0) - lock) * ease(3, dt);
        musicAmt += ((music ? 1 : 0) - musicAmt) * ease(1.8, dt);
        if (!music && t >= nextBeat && !Session.locked) { // own heartbeat; with music the beat comes from the bass
            pulse((0.5 + energy * 0.6) * Math.max(0.3, strength));
            let interval = (2.2 - energy * 1.5) * (1 - 0.35 * heat) / Math.max(0.3, strength);
            if (unwell) interval *= 0.6 + Math.random() * 0.9; // irregular when something is wrong
            nextBeat = t + interval;
        }
        if (flinchAt > 0 && t >= flinchAt) { flinchAt = -1; pulse(1.2 * strength + 0.4); }
        touchAmt *= Math.pow(0.965, dt * 60);
        touchWidth = Math.min(1.2, touchWidth + dt * 0.72);
        glow *= Math.pow(0.9, dt * 60);
        kick *= Math.pow(0.88, dt * 60);
        heartPhase += dt * 0.6 * (0.3 + energy) * Math.min(1, strength);
        waves = waves.map(w => ({ r: w.r + (3.2 + energy * 2) * 60 * dt, a: w.a * Math.pow(0.985, dt * 60) })).filter(w => w.r < 260 && w.a > 0.03);
    }

    // ---------------- colors: theme, fever, album ----------------
    function rgb(c) { return [c.r, c.g, c.b]; }
    function mixc(a, b, f) { return [0, 1, 2].map(i => a[i] + (b[i] - a[i]) * f); }
    function v4(c) { return Qt.vector4d(c[0], c[1], c[2], 1); }
    // one accent family, like the other desktop widgets: bands are shades of the
    // accent (toward the text color), the heart is the brightest
    readonly property var primary: rgb(Colors.accent)
    readonly property var shadeLight: mixc(primary, rgb(Colors.fg), 0.35)
    readonly property var shadeMid: mixc(primary, rgb(Colors.fg), 0.15)
    readonly property var shadeDim: mixc(primary, rgb(Colors.fgMuted), 0.45)
    readonly property var album: Album.colors.length ? Album.colors.map(rgb) : [primary]
    function bandColor(base, i) {
        let c = mixc(base, album[i % album.length], musicAmt * (0.45 + 0.35 * kick));
        return v4(mixc(c, rgb(Colors.alert), heat * 0.65));
    }

    // ---------------- the two shaders ----------------
    function axis(b, w) { return Qt.vector4d(b.ax[0], b.ax[1], b.ax[2], w); }
    function waveVec(key) { const w = waves; return Qt.vector4d(w[0]?.[key] ?? 0, w[1]?.[key] ?? 0, w[2]?.[key] ?? 0, w[3]?.[key] ?? 0); }

    ShaderEffect { // skin (behind the body)
        anchors.fill: parent
        readonly property real time: core.t
        readonly property real unit: core.unit
        readonly property size size: Qt.size(width, height)
        readonly property vector4d axC: core.axis(core.bands[0], core.bands[0].load > 0.005 ? core.bands[0].reach : 0)
        readonly property vector4d axM: core.axis(core.bands[1], core.bands[1].load > 0.005 ? core.bands[1].reach : 0)
        readonly property vector4d axS: core.axis(core.bands[2], core.bands[2].load > 0.005 ? core.bands[2].reach : 0)
        readonly property vector4d axN: core.axis(core.bands[3], core.bands[3].load > 0.005 ? core.bands[3].reach : 0)
        readonly property vector4d waveR: core.waveVec("r")
        readonly property vector4d waveA: core.waveVec("a")
        readonly property vector4d skin: Qt.vector4d(52, (0.3 + 0.7 * Math.min(1, core.strength)) * (core.watched ? 1.35 : 1), core.unwell ? 2.5 : 0, core.heat)
        readonly property vector4d touch: Qt.vector4d(core.touchAmt, core.touchWidth, -Math.PI / 4, 0) // notifications live top right
        // mic or camera in use: the skin turns alert (the senses are being used)
        readonly property vector4d colLine2: core.v4(core.rgb(Colors.border))
        readonly property vector4d colSkin: core.v4(core.mixc(core.mixc(core.primary, core.rgb(Colors.alert), Math.max(core.heat * 0.8, core.watched ? 0.6 : 0)), core.album[1 % core.album.length], core.musicAmt * 0.4 * (0.5 + core.kick)))
        fragmentShader: "../shaders/membrane.frag.qsb"
    }

    ShaderEffect { // heart, body and specks
        anchors.fill: parent
        mesh: GridMesh { resolution: Qt.size(899, 1) } // 450 particle slots
        readonly property real time: core.t
        readonly property real slots: 450
        readonly property real unit: core.unit
        readonly property point center: Qt.point(width / 2, height / 2)
        readonly property vector4d axC: core.axis(core.bands[0], core.bands[0].load)
        readonly property vector4d axM: core.axis(core.bands[1], core.bands[1].load)
        readonly property vector4d axS: core.axis(core.bands[2], core.bands[2].load)
        readonly property vector4d axN: core.axis(core.bands[3], core.bands[3].load)
        readonly property vector4d chaos: Qt.vector4d(core.bands[0].chaos, core.bands[1].chaos, core.bands[2].chaos, core.bands[3].chaos)
        readonly property vector4d phase: Qt.vector4d(core.bands[0].phase, core.bands[1].phase, core.bands[2].phase, core.bands[3].phase)
        readonly property vector4d rate: Qt.vector4d(core.bands[0].rate, core.bands[1].rate, core.bands[2].rate, core.bands[3].rate)
        readonly property vector4d waveR: core.waveVec("r")
        readonly property vector4d waveA: core.waveVec("a")
        readonly property vector4d life: Qt.vector4d(core.strength, core.lock, core.heat, core.glow)
        readonly property vector4d flow: Qt.vector4d(core.rx, core.tx, core.charging ? 1 : 0, core.food)
        readonly property vector4d misc: Qt.vector4d((9 + core.cpu * 5) * (0.6 + 0.4 * Math.min(1, core.strength)) * (1 + core.glow * 0.35) * (1 - core.lock * 0.4) * (1 + core.food * 0.4),
            30, Math.max(...core.bands.map(b => b.reach)) + 16, core.heartPhase)
        readonly property vector4d colC: core.bandColor(core.primary, 0)
        readonly property vector4d colM: core.bandColor(core.shadeLight, 1)
        readonly property vector4d colS: core.bandColor(core.shadeDim, 2)
        readonly property vector4d colN: core.bandColor(core.shadeMid, 3)
        readonly property vector4d colHeart: core.v4(core.mixc(core.mixc(core.mixc(core.primary, [1, 1, 1], 0.35), core.rgb(Colors.ok), Math.min(1, core.food) * 0.6), core.album[0], core.musicAmt * 0.3))
        readonly property vector4d colIn: core.v4(core.shadeLight)
        readonly property vector4d colFood: core.v4(core.rgb(Colors.ok))
        vertexShader: "../shaders/core.vert.qsb"
        fragmentShader: "../shaders/core.frag.qsb"
    }
}
