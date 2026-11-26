import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// The dashboard: the clock block's panel, flush under the right side of the bar.
//   1 overview  clock, weather now, calendar, player, resources
//   2 media     cover, spectrum, seek, controls, volume, synced lyrics
//   3 system    host, cpu (history, frequency, load), memory, gpu, drives,
//               network, busiest processes
//   4 weather   now, details, next 24 hours, 7 days
// 1-4 or h/l switch tabs, Esc closes. Super+I or the clock block opens it.
LazyLoader {
    active: Panels.open === "dash"

    PanelWindow {
        id: win
        property int tab: 0
        readonly property var tabs: ["overview", "media", "system", "weather"]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-dash"

        Binding { target: Procs; property: "watching"; value: win.tab === 2 } // only while the system tab shows
        Component.onDestruction: Procs.watching = false

        component Tile: Rectangle {
            default property alias content: tileCol.data
            property int padding: Style.pad
            Layout.fillWidth: true
            implicitHeight: tileCol.implicitHeight + padding * 2
            color: "transparent"
            border { width: Style.border; color: Colors.border }
            ColumnLayout { id: tileCol; anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.padding } spacing: Style.gap }
        }
        component Small: Mono { color: Colors.fgMuted; font.pixelSize: Style.fontSm }
        // a small framed label (the media tab's details)
        component Chip: Rectangle {
            property string text: ""
            property bool strong: false
            signal clicked()
            visible: text !== ""
            implicitWidth: chipText.implicitWidth + Style.pad * 1.5
            implicitHeight: chipText.implicitHeight + 2
            color: "transparent"
            border { width: Style.border; color: strong ? Colors.accent : Colors.border }
            Mono { id: chipText; anchors.centerIn: parent; text: parent.text; color: parent.strong ? Colors.accent : Colors.fgMuted; font.pixelSize: Style.fontSm }
            TapHandler { onTapped: parent.clicked() }
        }
        component Bar1: Rectangle { // a thin level bar
            property real value: 0
            Layout.fillWidth: true
            height: 3
            color: Colors.border
            Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.value)); height: parent.height; color: Colors.accent }
        }
        component Line: Canvas { // a line chart of values (0..max), redrawn when they change
            id: chart
            property var values: []
            property real max: 100
            Layout.fillWidth: true
            implicitHeight: Style.rowHeight * 1.6
            onValuesChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                c.strokeStyle = Colors.border; c.lineWidth = 1;
                c.beginPath(); c.moveTo(0, height - 0.5); c.lineTo(width, height - 0.5); c.stroke();
                const v = values, n = v.length;
                if (n < 2) return;
                const top = Math.max(max, ...v);
                c.strokeStyle = Colors.accent; c.lineWidth = 1.5;
                c.beginPath();
                v.forEach((x, i) => { const px = i / (n - 1) * width, py = height - 2 - x / top * (height - 4); i ? c.lineTo(px, py) : c.moveTo(px, py); });
                c.stroke();
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: panel
            anchors { top: parent.top; right: parent.right; topMargin: Style.barHeight - Style.border }
            width: Math.min(parent.width, 700)
            height: col.implicitHeight + Style.pad
            color: Colors.raised
            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Style.border; color: Colors.border }
            MouseArea { anchors.fill: parent }
            Item {
                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) Panels.close();
                    else if (event.text >= "1" && event.text <= "4") win.tab = Number(event.text) - 1;
                    else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) win.tab = (win.tab + 3) % 4;
                    else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) win.tab = (win.tab + 1) % 4;
                    else if (win.tab === 1 && event.key === Qt.Key_Space) Media.toggle();
                    else if (win.tab === 1 && event.key === Qt.Key_N) Media.next();
                    else if (win.tab === 1 && event.key === Qt.Key_P) Media.previous();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top }
                spacing: 0

                // tabs
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Style.pad
                    spacing: Style.padLg * 2
                    Repeater {
                        model: win.tabs
                        Column {
                            required property string modelData
                            required property int index
                            spacing: Style.gap
                            Mono { text: (index + 1) + " " + modelData; color: win.tab === index ? Colors.accent : Colors.fgMuted }
                            Rectangle { width: parent.width; height: 2; color: win.tab === index ? Colors.accent : "transparent" }
                            TapHandler { onTapped: win.tab = index }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }

                // ---------------- 1 overview ----------------
                GridLayout {
                    visible: win.tab === 0
                    Layout.fillWidth: true
                    Layout.margins: Style.pad
                    columns: 3
                    columnSpacing: Style.pad
                    rowSpacing: Style.pad
                    Tile {
                        Layout.alignment: Qt.AlignTop
                        Mono { text: Clock.format("HH:mm"); color: Colors.accent; font.pixelSize: Style.fontXl }
                        Mono { text: Clock.format("dddd dd MMMM").toLowerCase() }
                        Small {
                            readonly property date now: Clock.now
                            readonly property int doy: Math.floor((now - new Date(now.getFullYear(), 0, 0)) / 86400000)
                            text: "week " + Qt.formatDate(now, "w") + " · day " + doy + " / " + ((now.getFullYear() % 4 === 0) ? 366 : 365)
                        }
                        Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
                        Mono { text: Weather.ok ? Weather.deg(Weather.temp) + " " + Weather.condition : "--"; color: Weather.ok ? Colors.fg : Colors.fgMuted }
                        Small { visible: Weather.ok; text: "feels " + Weather.deg(Weather.feels) + " · rain " + (isNaN(Weather.rainChance) ? "--" : Weather.rainChance + "%") }
                        Small { visible: Weather.ok && Weather.days.length > 0; text: Weather.days.length ? "↑ " + Weather.deg(Weather.days[0].max) + " ↓ " + Weather.deg(Weather.days[0].min) + " · " + Weather.place : "" }
                    }
                    Tile {
                        id: cal
                        Layout.alignment: Qt.AlignTop
                        property int monthOffset: 0
                        readonly property date shown: { const d = new Date(Clock.now); d.setDate(1); d.setMonth(d.getMonth() + monthOffset); return d; }
                        readonly property var days: {
                            const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
                            const lead = (first.getDay() + 6) % 7; // weeks start on monday
                            const count = new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate();
                            const today = new Date(Clock.now), out = [];
                            for (let i = 0; i < lead; i++) out.push({ n: "", today: false });
                            for (let d = 1; d <= count; d++) out.push({ n: String(d), today: monthOffset === 0 && d === today.getDate() });
                            return out;
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            MonoButton { text: "‹"; color: Colors.accent; onClicked: cal.monthOffset -= 1 }
                            Mono { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(cal.shown, "MMMM yyyy").toLowerCase(); color: Colors.accent }
                            MonoButton { text: "›"; color: Colors.accent; onClicked: cal.monthOffset += 1 }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            columnSpacing: 0
                            rowSpacing: 1
                            Repeater {
                                model: ["mo", "tu", "we", "th", "fr", "sa", "su"]
                                Small { required property string modelData; text: modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            }
                            Repeater {
                                model: cal.days
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Style.fontMd + Style.gap
                                    color: modelData.today ? Colors.accent : "transparent"
                                    Mono { anchors.centerIn: parent; text: parent.modelData.n; font.pixelSize: Style.fontSm; color: parent.modelData.today ? Colors.accentFg : Colors.fg }
                                }
                            }
                        }
                    }
                    Tile {
                        Layout.alignment: Qt.AlignTop
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.pad
                            Rectangle {
                                implicitWidth: Style.rowHeight * 2; implicitHeight: implicitWidth
                                color: Colors.panel
                                border { width: Style.border; color: Colors.border }
                                Image { anchors { fill: parent; margins: Style.border } source: Media.cover; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.present ? Media.shownTitle : "nothing playing"; color: Media.present ? Colors.fg : Colors.fgMuted }
                                Small { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.shownArtist }
                            }
                        }
                        Bar1 { value: Media.progress }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Style.padLg
                            MonoButton { text: Icons.previous; color: Colors.accent; onClicked: Media.previous() }
                            MonoButton { text: Media.active ? Icons.pause : Icons.playIcon; color: Colors.accent; onClicked: Media.toggle() }
                            MonoButton { text: Icons.next; color: Colors.accent; onClicked: Media.next() }
                        }
                    }
                    // resources: one row across the three columns
                    RowLayout {
                        Layout.columnSpan: 3
                        Layout.fillWidth: true
                        spacing: Style.pad
                        Repeater {
                            model: [
                                { k: "cpu", v: Sys.cpu, t: Sys.pct(Sys.cpu) },
                                { k: "ram", v: Sys.memPercent, t: Sys.pct(Sys.memPercent) },
                                { k: "gpu", v: Sensors.gpu >= 0 ? Sensors.gpu * 100 : -1, t: Sensors.gpu >= 0 ? Math.round(Sensors.gpu * 100) + "%" : "--" },
                                { k: "disk", v: Disk.drives.length ? Disk.drives[0].used / Disk.drives[0].size * 100 : -1, t: Disk.drives.length ? Math.round(Disk.drives[0].used / Disk.drives[0].size * 100) + "%" : "--" },
                                { k: "battery", v: Battery.present ? Battery.percent : -1, t: Battery.present ? Battery.percent + "%" : "--" },
                                { k: "up", v: -1, t: Sys.duration(Sys.uptime) }
                            ]
                            Tile {
                                required property var modelData
                                Small { text: modelData.k }
                                Mono { text: modelData.t; color: Colors.accent }
                                Bar1 { visible: modelData.v >= 0; value: modelData.v / 100 }
                            }
                        }
                    }
                }

                // ---------------- 2 media ----------------
                ColumnLayout {
                    id: mediaTab
                    visible: win.tab === 1
                    Layout.fillWidth: true
                    Layout.margins: Style.pad
                    spacing: Style.pad
                    readonly property var song: Media.recognized // the real names and details when identified
                    function clock(s) { return Math.floor(s / 60) + ":" + String(Math.floor(s % 60)).padStart(2, "0"); }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.padLg
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 170; implicitHeight: 170
                            color: Colors.panel
                            border { width: Style.border; color: Colors.border }
                            Image { anchors { fill: parent; margins: Style.border } source: Media.cover; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            Mono { anchors.centerIn: parent; visible: Media.cover === ""; text: Icons.music; color: Colors.fgMuted; font.pixelSize: Style.fontXl }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Style.gap
                            Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.present ? Media.shownTitle : "nothing playing"; font.pixelSize: Style.fontLg }
                            Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.shownArtist }
                            Small {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: [mediaTab.song?.album || Media.album, mediaTab.song?.year || ""].filter(x => x).join(" · ")
                            }
                            Flow { // details: genre, label, where it plays, identified by ear (only then), a link
                                Layout.fillWidth: true
                                Layout.topMargin: Style.gap
                                spacing: Style.gap
                                visible: Media.present
                                Chip { text: (mediaTab.song?.genre || "").toLowerCase() }
                                Chip { text: (mediaTab.song?.label || "").toLowerCase() }
                                Chip { text: Media.player ? Media.player.identity.toLowerCase() : "" }
                                Chip { text: Lyrics.source === "ear" ? "identified by ear" : ""; strong: true }
                                Chip {
                                    text: !mediaTab.song?.url ? "" : mediaTab.song.url.includes("shazam") ? "open in shazam ↗" : "open in apple music ↗"
                                    onClicked: Qt.openUrlExternally(mediaTab.song.url)
                                }
                            }
                            // spectrum (cava), square bars. A fixed height (Layout.preferredHeight):
                            // a layout sizes a Row by its tallest bar, and bars sized from the Row's
                            // height would then shrink it a little on every update, down to nothing.
                            Row {
                                id: spectrum
                                readonly property real full: Style.rowHeight * 1.6
                                Layout.topMargin: Style.pad
                                Layout.preferredHeight: full
                                spacing: 2
                                Repeater {
                                    model: 40
                                    Rectangle {
                                        required property int index
                                        width: 5
                                        height: Math.max(1, (Visualizer.bars[index] ?? 0) * spectrum.full)
                                        anchors.bottom: parent.bottom
                                        color: Colors.accent
                                        opacity: 0.4 + 0.6 * (1 - index / 40)
                                    }
                                }
                            }
                            // seek: click the bar
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: Style.pad
                                Bar1 { anchors.verticalCenter: parent.verticalCenter; width: parent.width; value: Media.progress }
                                TapHandler {
                                    enabled: Media.player?.canSeek ?? false
                                    onTapped: point => { Media.player.position = point.position.x / parent.width * Media.length; }
                                }
                            }
                            RowLayout { // time; the video's own title when the song was identified under another name
                                Layout.fillWidth: true
                                spacing: Style.pad
                                Small { text: mediaTab.clock(Media.position) }
                                Small {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideMiddle
                                    text: mediaTab.song && Media.title !== Media.shownTitle ? "\"" + Media.title + "\"" : ""
                                }
                                Small { text: mediaTab.clock(Media.length) }
                            }
                            RowLayout {
                                spacing: Style.padLg
                                MonoButton {
                                    visible: Media.player?.shuffleSupported ?? false
                                    text: Icons.shuffle
                                    color: Media.player?.shuffle ? Colors.accent : Colors.fgMuted
                                    onClicked: Media.player.shuffle = !Media.player.shuffle
                                }
                                MonoButton { text: Icons.previous; color: Colors.accent; onClicked: Media.previous() }
                                MonoButton { text: Media.active ? Icons.pause : Icons.playIcon; color: Colors.accent; font.pixelSize: Style.fontLg; onClicked: Media.toggle() }
                                MonoButton { text: Icons.next; color: Colors.accent; onClicked: Media.next() }
                                MonoButton {
                                    visible: Media.player?.loopSupported ?? false
                                    text: Media.player?.loopState === MprisLoopState.None ? Icons.repeatOff : Icons.repeat
                                    color: Media.player?.loopState === MprisLoopState.None ? Colors.fgMuted : Colors.accent
                                    onClicked: Media.player.loopState = Media.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                        : Media.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                                }
                                Item { Layout.fillWidth: true }
                                Small { text: (Audio.muted ? Icons.volumeOff : Icons.volume) + " " + (Audio.ready ? Audio.volume + "%" : "--") }
                            }
                        }
                    }
                    // lyrics: a 5-line window that follows the song (past fade, current in the
                    // accent, coming muted); plain lyrics when not synced; else what it's doing
                    Tile {
                        visible: Media.present
                        RowLayout {
                            Layout.fillWidth: true
                            visible: Lyrics.lines.length > 0 || Lyrics.plain !== ""
                            Small { Layout.fillWidth: true; text: Lyrics.lines.length ? "" : "lyrics · not synced, so nothing is highlighted" }
                            Small { text: (Lyrics.lines.length ? "synced" : "plain") + " · lrclib" }
                        }
                        Repeater {
                            model: Lyrics.lines.length ? 5 : 0
                            Mono {
                                required property int index
                                readonly property int at: Lyrics.index + index - 2 // two before, the current one, two after
                                readonly property bool now: index === 2
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: at >= 0 && at < Lyrics.lines.length ? Lyrics.lines[at].text : ""
                                color: now ? Colors.accent : Colors.fgMuted
                                opacity: now ? 1 : index < 2 ? 0.45 + 0.2 * index : 1 - 0.2 * (index - 3)
                                font.pixelSize: now ? Style.fontLg : Style.fontSm
                            }
                        }
                        Flickable { // plain lyrics: scroll them
                            visible: Lyrics.lines.length === 0 && Lyrics.plain !== ""
                            Layout.fillWidth: true
                            implicitHeight: Math.min(plainText.implicitHeight, Style.rowHeight * 6)
                            contentHeight: plainText.implicitHeight
                            clip: true
                            Small { id: plainText; width: parent.width; wrapMode: Text.Wrap; text: Lyrics.plain; lineHeight: 1.2 }
                        }
                        Small { // no lyrics: say why (or what it is doing)
                            visible: Lyrics.lines.length === 0 && Lyrics.plain === ""
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: Icons.music + " " + (Lyrics.status || "no lyrics")
                        }
                    }
                }

                // ---------------- 3 system ----------------
                ColumnLayout {
                    visible: win.tab === 2
                    Layout.fillWidth: true
                    Layout.margins: Style.pad
                    spacing: Style.pad
                    Small { text: [Sys.host, Sys.kernel ? "linux " + Sys.kernel : "", "up " + Sys.duration(Sys.uptime), Updates.count >= 0 ? Updates.count + " updates" : ""].filter(x => x).join(" · ") }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.pad
                        Tile {
                            Layout.preferredWidth: 3
                            RowLayout { Layout.fillWidth: true; Mono { text: "cpu · " + Sys.cores.length + " cores"; Layout.fillWidth: true } Mono { text: Sys.pct(Sys.cpu); color: Colors.accent } }
                            Row { // per-core, right now
                                spacing: 2
                                Repeater {
                                    model: Sys.cores
                                    Rectangle { required property var modelData; width: 12; height: 8; color: Colors.accent; opacity: 0.12 + 0.88 * modelData / 100 }
                                }
                            }
                            Line { values: Sys.cpuHistory }
                            Small { text: (Sys.temp >= 0 ? Math.round(Sys.temp) + "°C" : "--") + " · " + (Sys.mhz > 0 ? (Sys.mhz / 1000).toFixed(2) + " GHz" : "--") + " · load " + (Sys.load.length ? Sys.load.map(x => x.toFixed(2)).join(" ") : "--") }
                        }
                        ColumnLayout {
                            Layout.preferredWidth: 2
                            Layout.fillWidth: true
                            spacing: Style.pad
                            Tile {
                                RowLayout { Layout.fillWidth: true; Mono { text: "memory"; Layout.fillWidth: true } Mono { text: Sys.gib(Sys.memUsed) + " / " + Sys.gib(Sys.memTotal); color: Colors.accent } }
                                Bar1 { value: Sys.memPercent / 100 }
                                Small { text: "swap " + Sys.gib(Sys.swapUsed) + " / " + Sys.gib(Sys.swapTotal) }
                            }
                            Tile {
                                RowLayout { Layout.fillWidth: true; Mono { text: "gpu"; Layout.fillWidth: true } Mono { text: Sensors.gpu >= 0 ? Math.round(Sensors.gpu * 100) + "%" : "--"; color: Colors.accent } }
                                Bar1 { value: Math.max(0, Sensors.gpu) }
                                Small { text: "nvme " + (Sensors.nvmeTemp > 0 ? Math.round(Sensors.nvmeTemp) + "°C" : "--") }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.pad
                        Tile {
                            Layout.preferredWidth: 2
                            Mono { text: "drives" }
                            Repeater {
                                model: Disk.drives
                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Small { text: modelData.label + " " + Math.round(modelData.used / modelData.size * 100) + "% · " + Sys.gib(modelData.used) + " / " + Sys.gib(modelData.size) }
                                    Bar1 { value: modelData.used / modelData.size }
                                }
                            }
                            Small { text: "read " + Sys.rate(Disk.readRate) + "/s · write " + Sys.rate(Disk.writeRate) + "/s" }
                        }
                        Tile {
                            Layout.preferredWidth: 3
                            RowLayout { Layout.fillWidth: true; Mono { text: "network" + (Wifi.ssid ? " · " + Wifi.ssid : ""); Layout.fillWidth: true } Small { text: Icons.down + Sys.rate(Sys.rxRate) + "/s " + Icons.up + Sys.rate(Sys.txRate) + "/s" } }
                            MirrorWave { Layout.fillWidth: true; implicitHeight: Style.rowHeight * 1.6; up: Sys.rxHistory; down: Sys.txHistory; count: 60 }
                        }
                    }
                    Tile {
                        RowLayout { Layout.fillWidth: true; Small { text: "busiest now"; Layout.fillWidth: true } Small { text: "cpu"; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight } Small { text: "ram"; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight } }
                        Repeater {
                            model: Procs.top
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Mono { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                                Mono { text: modelData.cpu.toFixed(0) + "%"; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight; color: Colors.accent }
                                Mono { text: Sys.gib(modelData.mem); Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight; color: Colors.fgMuted }
                            }
                        }
                    }
                }

                // ---------------- 4 weather ----------------
                ColumnLayout {
                    visible: win.tab === 3
                    Layout.fillWidth: true
                    Layout.margins: Style.pad
                    spacing: Style.pad
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.pad
                        Tile {
                            Layout.preferredWidth: 2
                            Small { text: Weather.place + (Weather.ok ? "" : " · offline") }
                            Mono { text: Weather.deg(Weather.temp); color: Colors.accent; font.pixelSize: Style.fontXl }
                            Mono { text: Weather.condition }
                            Small { text: "feels " + Weather.deg(Weather.feels) }
                        }
                        GridLayout {
                            Layout.preferredWidth: 3
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: Style.pad
                            rowSpacing: Style.pad
                            Repeater {
                                model: [
                                    { k: "humidity", t: isNaN(Weather.humidity) ? "--" : Math.round(Weather.humidity) + "%" },
                                    { k: "wind", t: isNaN(Weather.wind) ? "--" : Math.round(Weather.wind) + " km/h" },
                                    { k: "rain", t: isNaN(Weather.rainChance) ? "--" : Weather.rainChance + "%" },
                                    { k: "uv", t: isNaN(Weather.uv) ? "--" : Weather.uv.toFixed(0) },
                                    { k: "sunrise", t: Weather.sunrise || "--" },
                                    { k: "sunset", t: Weather.sunset || "--" }
                                ]
                                Tile { required property var modelData; Small { text: modelData.k } Mono { text: modelData.t } }
                            }
                        }
                    }
                    Tile {
                        Small { text: "next 24 hours" }
                        Line { values: Weather.hours.map(h => h.temp); max: 0; implicitHeight: Style.rowHeight * 2.4 }
                        RowLayout {
                            Layout.fillWidth: true
                            Repeater {
                                model: Weather.hours.filter((h, i) => i % 6 === 0)
                                Small { required property var modelData; Layout.fillWidth: true; text: modelData.hour + ":00 " + Weather.deg(modelData.temp) + (modelData.rain >= 30 ? " · " + modelData.rain + "%" : "") }
                            }
                        }
                    }
                    Tile {
                        Small { text: "7 days" }
                        Repeater {
                            model: Weather.days
                            RowLayout {
                                required property var modelData
                                readonly property real lo: Math.min(...Weather.days.map(d => d.min))
                                readonly property real hi: Math.max(...Weather.days.map(d => d.max))
                                Layout.fillWidth: true
                                spacing: Style.pad
                                Mono { text: modelData.day; Layout.preferredWidth: 60 }
                                Small { text: Weather.describe(modelData.code); Layout.preferredWidth: 110; elide: Text.ElideRight }
                                Small { text: Weather.deg(modelData.min); Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                Item { // the day's range on the week's scale
                                    Layout.fillWidth: true
                                    implicitHeight: 3
                                    Rectangle { anchors.fill: parent; color: Colors.border }
                                    Rectangle {
                                        x: parent.width * (modelData.min - parent.parent.lo) / Math.max(1, parent.parent.hi - parent.parent.lo)
                                        width: parent.width * (modelData.max - modelData.min) / Math.max(1, parent.parent.hi - parent.parent.lo)
                                        height: parent.height
                                        color: Colors.accent
                                    }
                                }
                                Mono { text: Weather.deg(modelData.max); Layout.preferredWidth: 36 }
                                Small { text: modelData.rain >= 20 ? modelData.rain + "%" : ""; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
                Small {
                    Layout.margins: Style.pad
                    text: "1-4 or h/l tabs" + (win.tab === 1 ? " · space play/pause · n/p next/previous" : "") + " · esc close"
                }
            }
        }
    }
}
