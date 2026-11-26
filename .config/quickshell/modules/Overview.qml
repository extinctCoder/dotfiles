import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Super+Tab: every workspace with live previews of its windows (captured only
// while this is open). Type to filter, Enter jumps to the first match,
// click a window to jump to it, drag it onto another workspace to move it.
LazyLoader {
    active: Panels.open === "overview"

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.88)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-overview"

        // workspaces 1..(highest in use + 1), so there is always an empty one to drop into
        readonly property var existing: Array.from(Hypr.workspaces.values).filter(w => w.id > 0)
        readonly property int count: Math.min(9, Math.max(1, ...existing.map(w => w.id)) + 1)
        function wsById(id) { return existing.find(w => w.id === id) ?? null; }
        function appId(t) { return t.wayland ? t.wayland.appId : (t.lastIpcObject?.class ?? ""); }
        function matches(t) {
            const q = search.text.trim().toLowerCase();
            return q === "" || (t.title + " " + appId(t)).toLowerCase().includes(q);
        }
        function icon(t) {
            const id = appId(t);
            const entry = id ? DesktopEntries.heuristicLookup(id) : null;
            return Quickshell.iconPath(entry ? entry.icon : id.toLowerCase(), "application-x-executable");
        }
        function jump(t) { Panels.close(); Hypr.focusWindow(t.address); }
        function firstMatch() {
            for (const w of existing) for (const t of Array.from(w.toplevels.values)) if (matches(t)) return t;
            return null;
        }

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        ColumnLayout {
            anchors { fill: parent; margins: Style.padLg * 2 }
            spacing: Style.padLg

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.pad
                Mono { text: "windows>"; color: Colors.accent; font.pixelSize: Style.fontLg }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    focus: true
                    color: Colors.fg
                    font.family: Style.font
                    font.pixelSize: Style.fontLg
                    Component.onCompleted: forceActiveFocus()
                    Keys.onEscapePressed: Panels.close()
                    Keys.onReturnPressed: { const t = win.firstMatch(); if (t) win.jump(t); }
                    Keys.onEnterPressed: { const t = win.firstMatch(); if (t) win.jump(t); }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: Math.min(3, win.count)
                columnSpacing: Style.padLg
                rowSpacing: Style.padLg

                Repeater {
                    model: win.count
                    Rectangle {
                        id: wsBox
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var ws: win.wsById(wsId)
                        readonly property bool current: Hypr.focusedId === wsId
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: drop.containsDrag ? Colors.raised : "transparent"
                        border { width: current ? 2 : Style.border; color: current || drop.containsDrag ? Colors.accent : Colors.border }

                        Mono {
                            anchors { left: parent.left; top: parent.top; margins: Style.pad }
                            text: wsBox.current ? "[" + wsBox.wsId + "]" : String(wsBox.wsId)
                            color: wsBox.current ? Colors.accent : Colors.fgMuted
                        }
                        Mono {
                            anchors.centerIn: parent
                            visible: !wsBox.ws || wsBox.ws.toplevels.values.length === 0
                            text: "empty"
                            color: Colors.fgMuted
                        }

                        DropArea {
                            id: drop
                            anchors.fill: parent
                            keys: ["window"]
                            onDropped: drag => { Hypr.moveWindow(drag.source.address, wsBox.wsId); drag.accept(); }
                        }

                        Flow {
                            anchors { fill: parent; margins: Style.pad; topMargin: Style.pad * 2 + Style.fontMd }
                            spacing: Style.pad
                            Repeater {
                                model: wsBox.ws ? wsBox.ws.toplevels : []
                                Item {
                                    id: tile
                                    required property var modelData
                                    readonly property string address: modelData.address
                                    readonly property int n: Math.max(1, wsBox.ws ? wsBox.ws.toplevels.values.length : 1)
                                    visible: win.matches(modelData)
                                    width: Math.max(80, (wsBox.width - Style.pad * 2) / Math.min(n, 2) - Style.pad)
                                    height: Math.max(60, (wsBox.height - Style.pad * 4 - Style.fontMd) / Math.ceil(n / 2) - Style.pad)

                                    // while dragging, lift this workspace box above the others
                                    Binding { target: wsBox; property: "z"; value: 10; when: grab.drag.active }

                                    Drag.active: grab.drag.active
                                    Drag.keys: ["window"]
                                    Drag.source: tile
                                    Drag.hotSpot: Qt.point(width / 2, height / 2)

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Colors.panel
                                        border { width: Style.border; color: grab.containsMouse ? Colors.accent : Colors.border }
                                        clip: true

                                        ScreencopyView {
                                            anchors { fill: parent; margins: Style.border; bottomMargin: label.height }
                                            captureSource: tile.modelData.wayland
                                            live: true
                                        }
                                        Row {
                                            id: label
                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.gap }
                                            spacing: Style.gap
                                            AppIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                size: Style.fontMd
                                                name: win.appId(tile.modelData)
                                                fallback: win.icon(tile.modelData)
                                            }
                                            Mono {
                                                width: parent.width - Style.fontMd - Style.gap
                                                elide: Text.ElideRight
                                                font.pixelSize: Style.fontSm
                                                text: tile.modelData.title
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: grab
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        drag.target: tile
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        property point start
                                        onPressed: start = Qt.point(tile.x, tile.y)
                                        onReleased: {
                                            const moved = Math.abs(tile.x - start.x) + Math.abs(tile.y - start.y) > 8;
                                            if (moved) tile.Drag.drop(); else win.jump(tile.modelData);
                                            tile.x = start.x; tile.y = start.y; // the Flow re-lays it out
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
