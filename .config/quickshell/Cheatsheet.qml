import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property var binds: [] // { key, desc, group }
    property var leader: [] // { key, desc, cmd }
    property string mode: "" // "", "sheet" or "leader"

    function openAs(m) {
        loader.running = true; // re-read keymap.lua every time
        mode = m;
    }

    Component.onCompleted: loader.running = true

    Process {
        id: loader
        command: ["lua", "-e",
            "package.path = os.getenv('HOME') .. '/.config/hypr/?.lua;' .. package.path " +
            "local k = require('keymap') " +
            "for _, b in ipairs(k.binds) do print('B\\t' .. b[1] .. '\\t' .. b[3] .. '\\t' .. b[4]) end " +
            "for _, l in ipairs(k.leader) do print('L\\t' .. l[1] .. '\\t' .. l[3] .. '\\t' .. l[2]) end"]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = [];
                const l = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f[0] === "B") b.push({ key: f[1], desc: f[2], group: f[3] });
                    if (f[0] === "L") l.push({ key: f[1], desc: f[2], cmd: f[3] });
                }
                root.binds = b;
                root.leader = l;
            }
        }
    }

    IpcHandler {
        target: "keys"
        function cheatsheet(): void {
            if (root.mode === "sheet") root.mode = ""; else root.openAs("sheet");
        }
        function leader(): void {
            if (root.mode === "leader") root.mode = ""; else root.openAs("leader");
        }
    }

    // ---------- cheatsheet ----------
    LazyLoader {
        active: root.mode === "sheet"

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-cheatsheet"

            MouseArea { anchors.fill: parent; onClicked: root.mode = "" }

            Rectangle {
                id: sheet
                anchors.centerIn: parent
                width: 720
                height: Math.min(parent.height * 0.8, body.implicitHeight + Style.pad * 2)
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                MouseArea { anchors.fill: parent }

                readonly property var rows: root.binds.filter(b =>
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
                            Keys.onEscapePressed: root.mode = ""
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
                            required property var modelData
                            width: ListView.view.width
                            height: Style.rowHeight
                            spacing: Style.pad

                            Mono { Layout.preferredWidth: 110; text: modelData.group; color: Colors.fgMuted }
                            Mono { Layout.preferredWidth: 260; text: modelData.key; color: Colors.accent }
                            Mono { Layout.fillWidth: true; text: modelData.desc; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }
    }

    // ---------- leader menu (which-key) ----------
    LazyLoader {
        active: root.mode === "leader"

        PanelWindow {
            anchors { bottom: true; left: true; right: true }
            implicitHeight: grid.implicitHeight + Style.pad * 2
            exclusiveZone: 0
            color: Colors.panel
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-leader"

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
                    if (event.key === Qt.Key_Escape) { root.mode = ""; return; }
                    const hit = root.leader.find(l => l.key === event.text);
                    if (hit) {
                        Quickshell.execDetached(["sh", "-c", hit.cmd]);
                        root.mode = "";
                    }
                }

                GridLayout {
                    id: grid
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                    columns: 4
                    columnSpacing: Style.padLg
                    rowSpacing: Style.gap

                    Repeater {
                        model: root.leader

                        RowLayout {
                            required property var modelData
                            spacing: Style.pad
                            Mono { text: modelData.key; color: Colors.accent; font.bold: true }
                            Mono { text: modelData.desc }
                        }
                    }
                }
            }
        }
    }
}
