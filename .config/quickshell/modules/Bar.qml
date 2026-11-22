import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Left: workspaces with their apps' icons. Center: the island.
// Right: status items (icon + value, accent), each opening a popup;
// the bell opens quick settings + notifications.
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

        function iconFor(t) {
            const id = t.wayland ? t.wayland.appId : (t.lastIpcObject?.class ?? "");
            const entry = id ? DesktopEntries.heuristicLookup(id) : null;
            return Quickshell.iconPath(entry ? entry.icon : id.toLowerCase(), "application-x-executable");
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Style.border
            color: Colors.border
        }

        // left: workspaces 1 [2] 3, each followed by its apps' icons
        RowLayout {
            anchors { left: parent.left; leftMargin: Style.pad; verticalCenter: parent.verticalCenter }
            spacing: Style.pad

            Repeater {
                model: Hypr.workspaces
                Row {
                    id: ws
                    required property var modelData
                    readonly property bool current: Hypr.focusedId === modelData.id
                    visible: modelData.id > 0
                    spacing: Style.gap

                    MonoButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ws.current ? "[" + ws.modelData.id + "]" : " " + ws.modelData.id + " "
                        color: ws.current ? Colors.accent : Colors.fgMuted
                        font.bold: ws.current
                        onClicked: Hypr.focusWorkspace(ws.modelData.id)
                    }
                    Repeater {
                        model: ws.modelData.toplevels
                        IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Style.fontMd
                            source: bar.iconFor(modelData)
                            opacity: ws.current ? 1 : 0.55
                        }
                    }
                }
            }
        }

        Island {
            anchors.centerIn: parent
            maxWidth: Math.round(bar.width * 0.38)
        }

        // right: status items
        RowLayout {
            anchors { right: parent.right; rightMargin: Style.pad; verticalCenter: parent.verticalCenter }
            spacing: Style.pad

            StatusItem {
                id: privacyItem
                visible: Privacy.active
                icon: (Privacy.micApps.length ? Icons.mic : "") + (Privacy.videoApps.length ? " " + Icons.video : "")
                color: Colors.alert
                popup: "privacy"
            }
            StatusItem {
                visible: Session.stayAwake
                icon: Icons.coffee
                onClicked: Session.stayAwake = false
            }
            StatusItem {
                id: netItem
                icon: Wifi.connected ? Icons.wifi : Icons.wifiOff
                value: Wifi.connected ? Icons.down + Sys.rate(Sys.rxRate) : "--"
                color: Wifi.connected ? Colors.accent : Colors.alert
                popup: "net"
            }
            Mono { text: "·"; color: Colors.border }
            StatusItem { id: cpuItem; icon: Icons.cpu; value: Sys.pct(Sys.cpu); popup: "cpu" }
            Mono { text: "·"; color: Colors.border }
            StatusItem { id: memItem; icon: Icons.mem; value: Sys.pct(Sys.memPercent); popup: "mem" }
            Mono { text: "·"; color: Colors.border }
            StatusItem {
                id: volItem
                icon: Audio.muted ? Icons.volumeOff : Icons.volume
                value: Audio.ready ? (Audio.muted ? "muted" : Audio.volume + "%") : "--"
                popup: "vol"
            }
            Mono { visible: Battery.present; text: "·"; color: Colors.border }
            StatusItem {
                id: batItem
                visible: Battery.present
                icon: Battery.charging ? Icons.charging : Icons.battery
                value: Battery.percent + "%"
                color: Battery.low ? Colors.alert : Colors.accent
                popup: "bat"
            }
            Mono { text: "·"; color: Colors.border }
            StatusItem { id: clockItem; value: Clock.format("ddd dd  HH:mm"); popup: "clock" }
            Mono { text: "·"; color: Colors.border }
            StatusItem {
                icon: Notifs.unread > 0 ? Icons.bellBadge : (Notifs.dnd ? Icons.bellOff : Icons.bell)
                onClicked: Panels.toggle("quick")
            }
            StatusItem {
                icon: Icons.power
                color: Colors.fgMuted
                onClicked: Panels.toggle("power")
            }
        }

        PrivacyPopup { item: privacyItem }
        NetPopup { item: netItem }
        CpuPopup { item: cpuItem }
        MemPopup { item: memItem }
        VolPopup { item: volItem }
        BatPopup { item: batItem }
        ClockPopup { item: clockItem }
    }
}
