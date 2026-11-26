import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// One bar, two sides, nothing in the middle:
//   left   logo (launcher) · workspaces 1-9 (hover: live preview) · the focused app
//   right  tray · values that matter right now · status block · clock block · power
// One frame = one panel: the status block opens quick settings (at the part you
// clicked), the clock block the dashboard, the logo the launcher, power the power
// menu. Tray icons are separate buttons with their own menus. Panels hang flush
// from the bar; an open block joins its panel (same color, no line between).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: Style.barHeight
        color: Colors.panel
        WlrLayershell.namespace: "quickshell-bar"

        // stay awake: while on, the session never idles (no dim, lock or sleep)
        IdleInhibitor { window: bar; enabled: Session.stayAwake }

        function appEntry(id) { return id ? DesktopEntries.heuristicLookup(id) : null; }
        function iconFor(id) {
            const entry = appEntry(id);
            return Quickshell.iconPath(entry ? entry.icon : id.toLowerCase(), "application-x-executable");
        }
        function workspace(id) { return Array.from(Hypr.workspaces.values).find(w => w.id === id) ?? null; }

        // the bar's bottom line (an open block covers its part of it)
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Style.border
            color: Colors.border
        }

        // a framed block of the bar: raised while hovered, joined to its panel while open
        component Block: Rectangle {
            id: blk
            property bool open: false
            property bool hovered: hover.hovered
            signal clicked()
            default property alias content: row.data
            implicitWidth: row.implicitWidth + Style.pad * 2
            implicitHeight: open ? Style.barHeight : Style.barHeight - Style.border
            Layout.alignment: Qt.AlignTop
            color: open || hovered ? Colors.raised : "transparent"
            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            HoverHandler { id: hover }
            TapHandler { onTapped: blk.clicked() }
            Row {
                id: row
                anchors.centerIn: parent
                anchors.verticalCenterOffset: blk.open ? -Style.border / 2 : 0
                spacing: Style.pad
            }
        }

        // ---------------- left ----------------
        RowLayout {
            id: left
            anchors { left: parent.left; top: parent.top; right: right.left; rightMargin: Style.padLg * 2 }
            height: Style.barHeight
            spacing: 0

            Block {
                open: Panels.open === "apps"
                onClicked: Panels.toggle("apps")
                Mono { text: Icons.logo; color: Colors.accent; font.pixelSize: Style.fontLg }
            }

            Item { implicitWidth: Style.padLg }

            // workspaces 1-9: empty = outline, used = filled, current = a wide accent bar,
            // urgent = alert color; hover shows a live preview, click goes there
            Row {
                spacing: Style.pad
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: 9
                    Item {
                        id: sq
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var ws: bar.workspace(wsId)
                        readonly property bool current: Hypr.focusedId === wsId
                        readonly property bool used: ws !== null && ws.toplevels.values.length > 0
                        readonly property bool urgent: used && Array.from(ws.toplevels.values).some(t => t.urgent)
                        width: current ? Style.fontMd * 1.8 : Style.fontMd * 0.75
                        height: Style.fontMd * 0.75
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on width { NumberAnimation { duration: Style.anim } }
                        Rectangle {
                            anchors.fill: parent
                            color: sq.urgent ? Colors.alert : sq.current ? Colors.accent : sq.used ? Colors.fgMuted : "transparent"
                            border { width: sq.used || sq.current ? 0 : Style.border; color: Colors.fgMuted }
                        }
                        HoverHandler { id: sqHover }
                        TapHandler { onTapped: Hypr.focusWorkspace(sq.wsId) }
                        // the preview opens after a short hover, so passing over the squares stays quiet
                        Timer { id: peek; interval: 280; running: sqHover.hovered && !sq.current; onTriggered: preview.active = true }
                        Connections { target: sqHover; function onHoveredChanged() { if (!sqHover.hovered) preview.active = false; } }
                        LazyLoader {
                            id: preview
                            active: false
                            PopupWindow {
                                anchor.item: sq
                                anchor.rect.x: -Style.pad
                                anchor.rect.y: Style.barHeight - sq.mapToItem(null, 0, 0).y - 1
                                anchor.rect.width: 1
                                anchor.rect.height: 1
                                anchor.edges: Edges.Bottom | Edges.Left
                                anchor.gravity: Edges.Bottom | Edges.Right
                                visible: true
                                implicitWidth: 340
                                implicitHeight: 230
                                color: "transparent"
                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.raised
                                    border { width: Style.border; color: Colors.border }
                                    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: Style.border; color: Colors.raised }
                                    ColumnLayout {
                                        anchors { fill: parent; margins: Style.pad }
                                        spacing: Style.gap
                                        Mono {
                                            text: "workspace " + sq.wsId + (sq.used ? " · " + sq.ws.toplevels.values.length + " window" + (sq.ws.toplevels.values.length > 1 ? "s" : "") : " · empty")
                                            color: Colors.fgMuted
                                            font.pixelSize: Style.fontSm
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Colors.bg
                                            border { width: Style.border; color: Colors.border }
                                            Mono { anchors.centerIn: parent; visible: !sq.used; text: "empty"; color: Colors.fgMuted }
                                            Row {
                                                anchors { fill: parent; margins: Style.gap }
                                                spacing: Style.gap
                                                visible: sq.used
                                                Repeater {
                                                    model: sq.ws ? sq.ws.toplevels : []
                                                    Rectangle {
                                                        id: tile
                                                        required property var modelData
                                                        readonly property int n: Math.max(1, sq.ws ? sq.ws.toplevels.values.length : 1)
                                                        width: (parent.width - (n - 1) * Style.gap) / n
                                                        height: parent.height
                                                        color: Colors.panel
                                                        border { width: Style.border; color: Colors.border }
                                                        clip: true
                                                        ScreencopyView { // live, only while the preview is open
                                                            anchors { fill: parent; margins: Style.border; bottomMargin: tileLabel.height }
                                                            captureSource: tile.modelData.wayland
                                                            live: true
                                                        }
                                                        Mono {
                                                            id: tileLabel
                                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.gap }
                                                            elide: Text.ElideRight
                                                            font.pixelSize: Style.fontSm
                                                            text: tile.modelData.title
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // the scratchpad has windows (Super+S shows it)
                Mono {
                    visible: Hypr.scratchpadUsed
                    anchors.verticalCenter: parent.verticalCenter
                    text: "s"
                    color: Colors.accent
                    font.pixelSize: Style.fontSm
                }
            }

            Item { implicitWidth: Style.padLg + Style.pad }

            // the focused app: its icon, its name, the window title dimmed; one line, cut with …
            IconImage {
                visible: Hypr.windowApp !== ""
                implicitSize: Style.fontMd
                Layout.alignment: Qt.AlignVCenter
                source: Hypr.windowApp !== "" ? bar.iconFor(Hypr.windowApp) : ""
            }
            Item { implicitWidth: Style.pad; visible: Hypr.windowApp !== "" }
            Mono {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                textFormat: Text.StyledText
                readonly property string app: bar.appEntry(Hypr.windowApp)?.name ?? Hypr.windowApp
                text: Hypr.windowTitle === "" ? "" : (app ? app.toLowerCase() + "  " : "")
                    + "<font color=\"" + Colors.fgMuted + "\">" + Hypr.windowTitle.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</font>"
            }
        }

        // ---------------- right ----------------
        RowLayout {
            id: right
            anchors { right: parent.right; top: parent.top }
            height: Style.barHeight
            spacing: 0

            // tray: apps' icons, each its own button and menu (dimmer than the system's icons)
            Repeater {
                model: SystemTray.items
                Item {
                    id: tray
                    required property var modelData
                    implicitWidth: Style.barHeight
                    implicitHeight: Style.barHeight - Style.border
                    Layout.alignment: Qt.AlignTop
                    Rectangle { anchors.fill: parent; color: trayHover.hovered || trayMenu.active ? Colors.raised : "transparent" }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Style.fontMd
                        source: tray.modelData.icon
                        opacity: 0.75
                    }
                    HoverHandler { id: trayHover }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: tray.modelData.onlyMenu && tray.modelData.hasMenu ? trayMenu.active = !trayMenu.active : tray.modelData.activate()
                    }
                    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: tray.modelData.secondaryActivate() }
                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: if (tray.modelData.hasMenu) trayMenu.active = !trayMenu.active }
                    LazyLoader {
                        id: trayMenu
                        active: false
                        TrayMenu {
                            item: tray
                            menu: tray.modelData.menu
                            title: tray.modelData.tooltipTitle || tray.modelData.title || tray.modelData.id
                            onDone: trayMenu.active = false
                        }
                    }
                }
            }

            Item { implicitWidth: Style.padLg; visible: SystemTray.items.values.length > 0 }

            // values that matter right now (hidden otherwise)
            Row {
                spacing: Style.pad
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Style.padLg
                MonoButton {
                    visible: Privacy.active
                    text: (Privacy.micApps.length ? Icons.mic : "") + (Privacy.videoApps.length ? " " + Icons.video : "")
                    color: Colors.alert
                    onClicked: Panels.openQuick("audio")
                }
                MonoButton { visible: Session.stayAwake; text: Icons.coffee; color: Colors.accent; onClicked: Session.stayAwake = false }
                Mono { visible: Sys.rxRate + Sys.txRate > 1e6; text: Icons.down + Sys.rate(Sys.rxRate) + " " + Icons.up + Sys.rate(Sys.txRate); color: Colors.fgMuted }
                Mono { visible: Sys.cpu >= 70; text: Icons.cpu + " " + Math.round(Sys.cpu) + "%"; color: Sys.cpu >= 90 ? Colors.alert : Colors.accent }
                Mono { visible: Sys.memPercent >= 80; text: Icons.mem + " " + Math.round(Sys.memPercent) + "%"; color: Sys.memPercent >= 92 ? Colors.alert : Colors.accent }
                Mono {
                    visible: Battery.present && (Battery.percent < 30 || Battery.charging)
                    text: Battery.percent + "%"
                    color: Battery.low ? Colors.alert : Colors.accent
                }
            }

            // the status block: one frame, one panel (quick settings, at the part clicked)
            Block {
                open: Panels.open === "quick"
                onClicked: Panels.openQuick(Panels.quickSection)
                Repeater {
                    model: [
                        { s: "wifi", g: Wifi.radio && Wifi.connected ? Icons.wifi : Icons.wifiOff, warn: !Wifi.connected },
                        { s: "bt", g: Bluetooth.defaultAdapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff, warn: false },
                        { s: "audio", g: Audio.muted ? Icons.volumeOff : Icons.volume, warn: false },
                        { s: "battery", g: Battery.present ? (Battery.charging ? Icons.charging : Icons.batteryFor(Battery.percent)) : Icons.brightness, warn: Battery.low },
                        { s: "notifs", g: Notifs.unread > 0 ? Icons.bellBadge : Notifs.dnd ? Icons.bellOff : Icons.bell, warn: false }
                    ]
                    MonoButton {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.g
                        color: modelData.warn ? Colors.alert : Colors.accent
                        onClicked: Panels.openQuick(modelData.s)
                    }
                }
            }

            // the clock block: one frame, one panel (the dashboard)
            Block {
                open: Panels.open === "dash"
                onClicked: Panels.toggle("dash")
                Mono { text: Clock.format("ddd dd MMM").toLowerCase(); color: Colors.fgMuted; anchors.verticalCenter: parent.verticalCenter }
                Mono { text: Clock.format("HH:mm"); color: Colors.fg; anchors.verticalCenter: parent.verticalCenter }
                Mono { visible: Weather.ok; text: Weather.deg(Weather.temp); color: Colors.accent; anchors.verticalCenter: parent.verticalCenter }
            }

            Block {
                open: Panels.open === "power"
                onClicked: Panels.toggle("power")
                Mono { text: Icons.power; color: Colors.accent }
            }
        }
    }
}
