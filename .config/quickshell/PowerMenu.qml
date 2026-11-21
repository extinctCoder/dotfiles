import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu: Super + Shift + Escape, or the "power" button in the bar.
// Letter keys run an action; arrows/J/K + Enter work too.
// Reboot and shut down ask [y/n] first.
Scope {
    id: root
    property bool open: false
    property int index: 0
    property string confirming: "" // key of the action waiting for y/n

    readonly property var actions: [
        { key: "l", label: "lock",      confirm: false, cmd: ["qs", "ipc", "call", "lock", "lock"] },
        { key: "o", label: "log out",   confirm: false, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { key: "s", label: "sleep",     confirm: false, cmd: ["systemctl", "suspend"] },
        { key: "r", label: "reboot",    confirm: true,  cmd: ["systemctl", "reboot"] },
        { key: "x", label: "shut down", confirm: true,  cmd: ["systemctl", "poweroff"] }
    ]

    function show() {
        index = 0;
        confirming = "";
        open = true;
    }

    function run(a) {
        if (!a) return;
        if (a.confirm && confirming !== a.key) {
            confirming = a.key;
            return;
        }
        open = false;
        Quickshell.execDetached(a.cmd);
    }

    IpcHandler {
        target: "power"
        function toggle(): void { if (root.open) root.open = false; else root.show(); }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-power"

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Rectangle {
                anchors.centerIn: parent
                width: 320
                height: col.implicitHeight + Style.pad * 2
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                MouseArea { anchors.fill: parent } // clicks inside stay inside

                Item {
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const n = root.actions.length;
                        if (event.key === Qt.Key_Escape) {
                            root.open = false;
                        } else if (root.confirming !== "") {
                            if (event.text === "y") root.run(root.actions.find(a => a.key === root.confirming));
                            else root.confirming = "";
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                            root.index = (root.index + 1) % n;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                            root.index = (root.index + n - 1) % n;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.run(root.actions[root.index]);
                        } else {
                            root.run(root.actions.find(a => a.key === event.text));
                        }
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                    spacing: 0

                    Mono {
                        text: "power>"
                        color: Colors.accent
                        font.pixelSize: Style.fontLg
                        Layout.bottomMargin: Style.gap
                    }

                    Repeater {
                        model: root.actions

                        Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.index
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
                                onEntered: root.index = row.index
                                onClicked: root.run(row.modelData)
                            }
                        }
                    }

                    Mono {
                        visible: root.confirming !== ""
                        Layout.topMargin: Style.gap
                        color: Colors.alert
                        text: "[warn] " + (root.actions.find(a => a.key === root.confirming)?.label ?? "") + "? [y/n]"
                    }
                }
            }
        }
    }
}
