import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Top-right stack, log-style lines. Left click: default action + close.
// Right click: close. Non-critical ones leave after 5 s. Super+N clears all.
PanelWindow {
    visible: Notifs.any
    anchors { top: true; right: true }
    margins { top: Style.pad; right: Style.pad }
    exclusiveZone: 0
    implicitWidth: 360
    implicitHeight: stack.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: Style.gap

        Repeater {
            model: Notifs.list

            Rectangle {
                id: card
                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                Layout.fillWidth: true
                implicitHeight: line.implicitHeight + Style.pad * 2
                color: Colors.panel
                border { width: Style.border; color: card.critical ? Colors.alert : Colors.border }

                Mono {
                    id: line
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: card.critical ? Colors.alert : Colors.fg
                    text: (card.critical ? "[crit] " : "[info] ")
                        + (card.modelData.appName || "app") + ": " + card.modelData.summary
                        + (card.modelData.body ? "\n" + card.modelData.body : "")
                }

                Timer {
                    running: !card.critical
                    interval: 5000
                    onTriggered: card.modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => Notifs.activate(card.modelData, mouse.button === Qt.LeftButton)
                }
            }
        }
    }
}
