import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Super+/ : searchable cheatsheet of every keybind.
// Super+D : leader menu (which-key): press one letter to run it, Esc to cancel.
Scope {
    LazyLoader {
        active: Panels.open === "sheet"

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-cheatsheet"

            Component.onCompleted: Keymap.reload() // re-read keymap.lua every time

            MouseArea { anchors.fill: parent; onClicked: Panels.close() }

            Rectangle {
                id: sheet
                anchors.centerIn: parent
                width: 720
                height: Math.min(parent.height * 0.8, body.implicitHeight + Style.pad * 2)
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                MouseArea { anchors.fill: parent }

                readonly property var rows: Keymap.binds.filter(b =>
                    (b.key + " " + b.desc + " " + b.group).toLowerCase()
                        .includes(search.text.toLowerCase()))

                ColumnLayout {
                    id: body
                    anchors { fill: parent; margins: Style.pad }
                    spacing: Style.gap

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.pad
                        Mono { text: "keys>"; color: Colors.accent; font.pixelSize: Style.fontLg }
                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            focus: true
                            color: Colors.fg
                            font.family: Style.font
                            font.pixelSize: Style.fontLg
                            Component.onCompleted: forceActiveFocus()
                            Keys.onEscapePressed: Panels.close()
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: count * Style.rowHeight
                        clip: true
                        model: sheet.rows

                        delegate: RowLayout {
                            id: line
                            required property var modelData
                            width: ListView.view.width
                            height: Style.rowHeight
                            spacing: Style.pad

                            Mono { Layout.preferredWidth: 110; text: line.modelData.group; color: Colors.fgMuted }
                            Mono { Layout.preferredWidth: 260; text: line.modelData.key; color: Colors.accent }
                            Mono { Layout.fillWidth: true; text: line.modelData.desc; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        active: Panels.open === "leader"

        PanelWindow {
            anchors { bottom: true; left: true; right: true }
            implicitHeight: grid.implicitHeight + Style.pad * 2
            exclusiveZone: 0
            color: Colors.panel
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-leader"

            Component.onCompleted: Keymap.reload()

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Style.border
                color: Colors.border
            }

            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) { Panels.close(); return; }
                    const hit = Keymap.leader.find(l => l.key === event.text);
                    if (hit) {
                        Panels.close();
                        Quickshell.execDetached(["sh", "-c", hit.cmd]);
                    }
                }

                GridLayout {
                    id: grid
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                    columns: 4
                    columnSpacing: Style.padLg
                    rowSpacing: Style.gap

                    Repeater {
                        model: Keymap.leader

                        RowLayout {
                            id: entry
                            required property var modelData
                            spacing: Style.pad
                            Mono { text: entry.modelData.key; color: Colors.accent; font.bold: true }
                            Mono { text: entry.modelData.desc }
                        }
                    }
                }
            }
        }
    }
}
