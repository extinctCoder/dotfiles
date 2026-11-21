import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Scope {
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        onNotification: n => n.tracked = true
    }

    IpcHandler {
        target: "notifs"
        function clear(): void {
            for (const n of Array.from(server.trackedNotifications.values)) n.dismiss();
        }
    }

    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
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
                model: server.trackedNotifications

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
                        onClicked: mouse => {
                            const def = Array.from(card.modelData.actions)
                                .find(a => a.identifier === "default");
                            if (mouse.button === Qt.LeftButton && def) def.invoke();
                            card.modelData.dismiss();
                        }
                    }
                }
            }
        }
    }
}
