import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Left: workspaces 1 2 [3] 4. Center: window title.
// Right: wifi · vol · power profile · battery · clock · power menu.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: Style.barHeight
        color: Colors.panel
        WlrLayershell.namespace: "quickshell-bar"

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Style.border
            color: Colors.border
        }

        RowLayout {
            anchors { left: parent.left; leftMargin: Style.pad; verticalCenter: parent.verticalCenter }
            spacing: Style.gap

            Repeater {
                model: Hypr.workspaces

                MonoButton {
                    required property var modelData
                    readonly property bool current: Hypr.focusedId === modelData.id
                    visible: modelData.id > 0
                    text: current ? "[" + modelData.id + "]" : " " + modelData.id + " "
                    color: current ? Colors.accent : Colors.fgMuted
                    font.bold: current
                    onClicked: Hypr.focusWorkspace(modelData.id)
                }
            }
        }

        Mono {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width * 0.4)
            elide: Text.ElideRight
            color: Colors.fgMuted
            text: Hypr.windowTitle
        }

        RowLayout {
            anchors { right: parent.right; rightMargin: Style.pad; verticalCenter: parent.verticalCenter }
            spacing: Style.pad

            MonoButton {
                text: Wifi.connected ? "wifi " + Wifi.ssid : "wifi off"
                color: Wifi.connected ? Colors.fg : Colors.alert
                onClicked: Term.float(["nmtui"])
            }
            Mono { text: "·"; color: Colors.border }

            MonoButton {
                text: !Audio.ready ? "vol --" : Audio.muted ? "vol muted" : "vol " + Audio.volume + "%"
                onClicked: Term.float(["wiremix"])
            }
            Mono { text: "·"; color: Colors.border }

            MonoButton {
                text: Power.profileName
                onClicked: Power.cycleProfile()
            }
            Mono { text: "·"; color: Colors.border }

            Mono {
                visible: Battery.present
                text: "bat " + Battery.percent + "%" + (Battery.charging ? "+" : "")
                color: Battery.low ? Colors.alert : Colors.fg
            }
            Mono { visible: Battery.present; text: "·"; color: Colors.border }

            Mono { text: Clock.format("ddd dd  HH:mm") }
            Mono { text: "·"; color: Colors.border }

            MonoButton {
                text: "power"
                color: Colors.fgMuted
                onClicked: Panels.toggle("power")
            }
        }
    }
}
