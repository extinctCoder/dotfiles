import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Super+Shift+Escape or the bar's "power" button.
// Letter keys run an action; arrows/J/K + Enter work too. Reboot and shut down ask [y/n].
LazyLoader {
    active: Panels.open === "power"

    PanelWindow {
        id: win
        property int index: 0
        property string confirming: "" // key of the action waiting for y/n

        function run(a) {
            if (!a) return;
            if (a.confirm && confirming !== a.key) { confirming = a.key; return; }
            Panels.close();
            Power.run(a);
        }

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-power"

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            // flush under the right side of the bar (the power block opens it)
            anchors { top: parent.top; right: parent.right; topMargin: Style.barHeight - Style.border }
            width: 320
            height: col.implicitHeight + Style.pad * 2
            color: Colors.raised
            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Style.border; color: Colors.border }

            MouseArea { anchors.fill: parent }

            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    const n = Power.actions.length;
                    if (event.key === Qt.Key_Escape) {
                        Panels.close();
                    } else if (win.confirming !== "") {
                        if (event.text === "y") win.run(Power.actions.find(a => a.key === win.confirming));
                        else win.confirming = "";
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        win.index = (win.index + 1) % n;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        win.index = (win.index + n - 1) % n;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        win.run(Power.actions[win.index]);
                    } else {
                        win.run(Power.actions.find(a => a.key === event.text));
                    }
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Style.gap
                    Mono { text: Quickshell.env("USER") + (Sys.host ? "@" + Sys.host : ""); Layout.fillWidth: true; elide: Text.ElideRight }
                    Mono { text: "up " + Sys.duration(Sys.uptime); color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                    Mono { visible: Battery.present; text: Battery.percent + "%"; color: Battery.low ? Colors.alert : Colors.accent; font.pixelSize: Style.fontSm }
                }

                Repeater {
                    model: Power.actions

                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === win.index
                        Layout.fillWidth: true
                        implicitHeight: Style.rowHeight
                        color: selected ? Colors.accent : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                            spacing: Style.padLg
                            Mono {
                                text: row.modelData.key
                                font.bold: true
                                color: row.selected ? Colors.accentFg : Colors.accent
                            }
                            Mono {
                                Layout.fillWidth: true
                                text: row.modelData.label
                                color: row.selected ? Colors.accentFg : Colors.fg
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: win.index = row.index
                            onClicked: win.run(row.modelData)
                        }
                    }
                }

                Mono {
                    visible: win.confirming !== ""
                    Layout.topMargin: Style.gap
                    color: Colors.alert
                    text: "[warn] " + (Power.actions.find(a => a.key === win.confirming)?.label ?? "") + "? [y/n]"
                }
                Mono {
                    Layout.topMargin: Style.gap
                    text: "letter or ↑↓ + enter · esc close"
                    color: Colors.fgMuted
                    font.pixelSize: Style.fontSm
                }
            }
        }
    }
}
