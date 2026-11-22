import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.theme
import qs.services

// Desktop widgets: above the wallpaper, below every window, click-through.
// Every value is live; anything without data shows "--" or nothing.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {} // clicks go to the desktop/windows below
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-desktop"

        readonly property real unit: Math.min(width, height) / 100 // layout unit
        component Label: Mono { color: Colors.fgMuted; font.pixelSize: Style.fontSm }

        // ---------------- center: radial visualizer clock + lyrics ----------------
        Item {
            id: clock
            readonly property real ring: win.unit * 17   // inner radius of the bars
            readonly property real reach: win.unit * 6    // longest bar
            width: (ring + reach) * 2
            height: width
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -win.unit * 4 }

            // the album cover, heavily blurred and faint, inside the ring
            Image {
                id: art
                anchors.centerIn: parent
                width: clock.ring * 2; height: width
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }
            Rectangle { id: artMask; anchors.fill: art; radius: width / 2; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: art
                source: art
                visible: Media.active && art.status === Image.Ready
                opacity: 0.18
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Repeater {
                model: 72
                Item {
                    required property int index
                    readonly property real v: Visualizer.bars[index] ?? 0
                    anchors.centerIn: parent
                    width: 4
                    height: (clock.ring + clock.reach) * 2
                    rotation: index * 5
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.verticalCenter; bottomMargin: clock.ring }
                        width: 3
                        height: Math.max(2, parent.v * clock.reach)
                        color: Colors.accent
                        opacity: parent.v > 0 ? 0.85 : 0.2 // still ring when nothing plays
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                Mono {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Clock.format("HH:mm")
                    color: Colors.accent
                    font.pixelSize: win.unit * 9
                    font.letterSpacing: -win.unit * 0.3
                }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.format("dddd dd MMMM").toLowerCase(); font.pixelSize: Style.fontMd }
            }
        }

        Column {
            anchors { horizontalCenter: clock.horizontalCenter; top: clock.bottom; topMargin: win.unit * 2 }
            width: win.width * 0.4
            spacing: Style.gap
            visible: Media.active
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: Lyrics.previous; opacity: 0.6 }
            Mono {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Style.fontLg
                text: Lyrics.current
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Media.title + (Media.artist ? " · " + Media.artist : "")
            }
        }

        // ---------------- top left: drive rings + disk activity ----------------
        Item {
            id: drives
            anchors { left: parent.left; top: parent.top; leftMargin: win.unit * 6; topMargin: Style.barHeight + win.unit * 6 }
            readonly property real r: win.unit * 9
            readonly property var rings: Disk.drives.map(d => ({ label: d.label, used: d.used, size: d.size }))
                .concat(Sys.swapTotal > 0 ? [{ label: "swap", used: Sys.swapUsed, size: Sys.swapTotal }] : [])
            width: r * 2; height: r * 2

            Canvas {
                id: ringCanvas
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = Math.max(4, drives.r * 0.13);
                    drives.rings.forEach((d, i) => {
                        const rad = drives.r - w / 2 - i * w * 1.8;
                        if (rad <= w) return;
                        ctx.lineWidth = w;
                        ctx.strokeStyle = Colors.border;
                        ctx.beginPath(); ctx.arc(drives.r, drives.r, rad, 0, Math.PI * 2); ctx.stroke();
                        ctx.strokeStyle = Colors.accent;
                        ctx.globalAlpha = 1 - i * 0.25;
                        ctx.beginPath(); ctx.arc(drives.r, drives.r, rad, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * (d.size > 0 ? d.used / d.size : 0)); ctx.stroke();
                        ctx.globalAlpha = 1;
                    });
                }
                Connections { target: drives; function onRingsChanged() { ringCanvas.requestPaint(); } }
                Connections { target: Colors; function onAccentChanged() { ringCanvas.requestPaint(); } }
            }
            Column {
                anchors.centerIn: parent
                Mono { anchors.horizontalCenter: parent.horizontalCenter; text: drives.rings.length ? Sys.gib(drives.rings[0].size) : "--"; font.pixelSize: Style.fontLg }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "disk" }
            }
        }
        Column {
            anchors { left: drives.right; leftMargin: win.unit * 3; verticalCenter: drives.verticalCenter }
            spacing: Style.gap
            Repeater {
                model: drives.rings
                Mono {
                    required property var modelData
                    required property int index
                    opacity: 1 - index * 0.25
                    color: Colors.accent
                    text: modelData.label + "  " + (modelData.size > 0 ? Math.round(modelData.used / modelData.size * 100) : 0) + "% · " + Sys.gib(modelData.used) + "/" + Sys.gib(modelData.size)
                }
            }
            Item { width: 1; height: Style.pad }
            Label { text: "read " + Sys.rate(Disk.readRate) + "/s · write " + Sys.rate(Disk.writeRate) + "/s" }
            MirrorWave { width: win.unit * 22; height: win.unit * 5; up: Disk.readHistory; down: Disk.writeHistory; count: 40 }
        }

        // ---------------- bottom left: cpu heat strip + network wave ----------------
        Column {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: win.unit * 6; bottomMargin: win.unit * 6 }
            spacing: Style.pad
            Label { text: "cpu · " + Sys.cores.length + " cores · last 60s" }
            Grid {
                id: heat
                readonly property int cols: 30
                readonly property real cell: win.unit * 1.25
                readonly property var hist: Array(Math.max(0, cols - Sys.coreHistory.length)).fill(null).concat(Sys.coreHistory)
                rows: Math.max(1, Sys.cores.length)
                columns: cols
                flow: Grid.TopToBottom
                spacing: 2
                Repeater {
                    model: heat.rows * heat.cols
                    Rectangle {
                        required property int index
                        readonly property var sample: heat.hist[Math.floor(index / heat.rows)]
                        readonly property real v: sample ? (sample[index % heat.rows] ?? 0) : -1
                        width: heat.cell; height: heat.cell
                        color: v < 0 ? Colors.border : Colors.accent
                        opacity: v < 0 ? 0.3 : 0.12 + 0.88 * v / 100
                    }
                }
            }
            Item { width: 1; height: Style.pad }
            Label { text: Icons.down + " " + Sys.rate(Sys.rxRate) + "/s   " + Icons.up + " " + Sys.rate(Sys.txRate) + "/s" }
            MirrorWave { width: heat.width; height: win.unit * 7; up: Sys.rxHistory; down: Sys.txHistory; count: 60 }
        }

        // ---------------- top right: sun arc + weather ----------------
        Item {
            id: sun
            anchors { right: parent.right; top: parent.top; rightMargin: win.unit * 6; topMargin: Style.barHeight + win.unit * 6 }
            width: win.unit * 30
            height: win.unit * 13
            function mins(s) { return s ? Number(s.slice(0, 2)) * 60 + Number(s.slice(3, 5)) : -1; }
            readonly property real rise: mins(Weather.sunrise)
            readonly property real set: mins(Weather.sunset)
            readonly property real now: WorldClock.localHour * 60
            readonly property real f: rise >= 0 && set > rise && now >= 0 ? (now - rise) / (set - rise) : -1

            Canvas {
                id: sunCanvas
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: win.unit * 9
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height, x0 = 4, x2 = w - 4, base = h - 2, top = -h * 0.65;
                    const pt = t => [(1 - t) * (1 - t) * x0 + 2 * (1 - t) * t * (w / 2) + t * t * x2,
                                     (1 - t) * (1 - t) * base + 2 * (1 - t) * t * top + t * t * base];
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = Colors.border;
                    ctx.setLineDash([4, 6]);
                    ctx.beginPath(); for (let i = 0; i <= 40; i++) { const p = pt(i / 40); i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.beginPath(); ctx.moveTo(0, base); ctx.lineTo(w, base); ctx.stroke();
                    if (sun.f < 0) return;
                    const t = Math.max(0, Math.min(1, sun.f));
                    ctx.strokeStyle = Colors.accent;
                    ctx.beginPath(); for (let i = 0; i <= 40; i++) { const p = pt(t * i / 40); i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke();
                    const s = pt(t);
                    ctx.fillStyle = Colors.accent;
                    ctx.globalAlpha = sun.f > 1 ? 0.35 : 1; // after sunset the sun rests, dimmed
                    ctx.beginPath(); ctx.arc(s[0], s[1], 6, 0, Math.PI * 2); ctx.fill();
                }
                Connections { target: sun; function onFChanged() { sunCanvas.requestPaint(); } }
                Connections { target: Colors; function onAccentChanged() { sunCanvas.requestPaint(); } }
            }
            Label { anchors { left: parent.left; top: sunCanvas.bottom; topMargin: 2 }
                text: Weather.sunrise || "--" }
            Label { anchors { right: parent.right; top: sunCanvas.bottom; topMargin: 2 }
                text: Weather.sunset || "--" }
            Mono {
                anchors { horizontalCenter: parent.horizontalCenter; top: sunCanvas.bottom; topMargin: Style.pad * 2 }
                text: Weather.ok ? Weather.deg(Weather.temp) + " " + Weather.condition : "--"
                font.pixelSize: Style.fontLg
            }
        }

        // ---------------- right: world timeline (dark = night there) ----------------
        Column {
            anchors { right: parent.right; rightMargin: win.unit * 6; top: sun.bottom; topMargin: win.unit * 5 }
            spacing: Style.pad
            Repeater {
                model: [{ name: "dhaka", diffMin: 0, time: Clock.format("HH:mm") }].concat(WorldClock.times)
                Row {
                    id: zone
                    required property var modelData
                    required property int index
                    spacing: Style.pad
                    Mono { width: win.unit * 9; text: zone.modelData.name; color: zone.index === 0 ? Colors.accent : Colors.fgMuted; font.pixelSize: Style.fontSm }
                    Item {
                        width: win.unit * 16; height: Style.fontSm
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.fill: parent; color: Colors.border }
                        Repeater {
                            model: 24
                            Rectangle {
                                required property int index
                                // hour `index` on the Dhaka axis is local hour (index + offset) in that city
                                readonly property real lh: ((index + zone.modelData.diffMin / 60) % 24 + 24) % 24
                                visible: lh >= 19 || lh < 6
                                x: index * parent.width / 24; width: parent.width / 24 + 0.5; height: parent.height
                                color: Colors.bg
                            }
                        }
                        Rectangle {
                            visible: WorldClock.localHour >= 0
                            x: WorldClock.localHour / 24 * parent.width - 1; y: -3; width: 2; height: parent.height + 6
                            color: Colors.accent
                        }
                    }
                    Mono { text: zone.modelData.time; font.pixelSize: Style.fontSm }
                }
            }
        }

        // ---------------- bottom right: battery curve + power, uptime, updates ----------------
        Column {
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: win.unit * 6; bottomMargin: win.unit * 6 }
            spacing: Style.pad
            visible: Battery.present
            Label { text: "battery · last 6h" }
            Canvas {
                id: batCanvas
                width: win.unit * 30
                height: win.unit * 8
                readonly property var pts: BatteryLog.points.concat(Battery.present ? [{ t: Date.now() / 1000, p: Battery.percent, c: Battery.charging }] : [])
                onPtsChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height, end = Date.now() / 1000, start = end - 6 * 3600;
                    const X = t => (t - start) / (end - start) * w, Y = p => h - 2 - p / 100 * (h - 4);
                    ctx.strokeStyle = Colors.border; ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(0, h - 1); ctx.lineTo(w, h - 1); ctx.stroke();
                    const ps = pts.filter(p => p.t >= start);
                    ctx.fillStyle = Colors.raised; // charging stretches
                    for (let i = 1; i < ps.length; i++) if (ps[i].c) ctx.fillRect(X(ps[i - 1].t), 0, X(ps[i].t) - X(ps[i - 1].t), h);
                    if (ps.length < 2) return;
                    ctx.strokeStyle = Colors.accent; ctx.lineWidth = 2;
                    ctx.beginPath(); ps.forEach((p, i) => i ? ctx.lineTo(X(p.t), Y(p.p)) : ctx.moveTo(X(p.t), Y(p.p))); ctx.stroke();
                    ctx.fillStyle = Colors.accent;
                    const last = ps[ps.length - 1];
                    ctx.beginPath(); ctx.arc(X(last.t), Y(last.p), 4, 0, Math.PI * 2); ctx.fill();
                }
                Connections { target: Colors; function onAccentChanged() { batCanvas.requestPaint(); } }
            }
            Mono {
                text: Battery.percent + "% · " + (Battery.watts > 0 ? Battery.watts.toFixed(1) + "W" : "--")
                    + " · up " + Sys.duration(Sys.uptime)
                    + " · " + (Updates.count < 0 ? "--" : Updates.count) + " updates"
                font.pixelSize: Style.fontSm
            }
        }
    }
}
