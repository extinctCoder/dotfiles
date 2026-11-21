import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Super+Space: apps. Super+V: clipboard history.
// Fuzzy match, arrows or Tab to move, Enter to run, Esc or click outside to close.
LazyLoader {
    active: Panels.open === "apps" || Panels.open === "clip"

    PanelWindow {
        id: win
        readonly property bool clip: Panels.open === "clip"

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"

        Component.onCompleted: if (clip) Clipboard.load()

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: box
            anchors.centerIn: parent
            width: 560
            height: content.implicitHeight + Style.pad * 2
            color: Colors.panel
            border { width: Style.border; color: Colors.border }

            MouseArea { anchors.fill: parent } // clicks inside stay inside

            readonly property var results: win.clip ? Clipboard.search(input.text) : Apps.search(input.text)

            function activate(index) {
                const item = results[index];
                if (item === undefined) return;
                if (win.clip) Clipboard.copy(item);
                else Apps.launch(item);
                Panels.close();
            }

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                spacing: Style.gap

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.pad

                    Mono {
                        text: win.clip ? "clip>" : ">"
                        color: Colors.accent
                        font.pixelSize: Style.fontLg
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        focus: true
                        color: Colors.fg
                        selectionColor: Colors.accent
                        font.family: Style.font
                        font.pixelSize: Style.fontLg
                        Component.onCompleted: forceActiveFocus()
                        onTextChanged: list.currentIndex = 0
                        Keys.onEscapePressed: Panels.close()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onTabPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: box.activate(list.currentIndex)
                    }
                }

                Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: Math.min(count, 8) * Style.rowHeight
                    clip: true
                    model: box.results

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem
                        width: list.width
                        height: Style.rowHeight
                        color: selected ? Colors.accent : "transparent"

                        Mono {
                            anchors {
                                left: parent.left; right: parent.right
                                leftMargin: Style.pad; verticalCenter: parent.verticalCenter
                            }
                            elide: Text.ElideRight
                            color: row.selected ? Colors.accentFg : Colors.fg
                            text: win.clip ? Clipboard.label(row.modelData) : row.modelData.name
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: box.activate(row.index)
                        }
                    }
                }

                Mono {
                    visible: list.count === 0
                    text: "[info] no matches"
                    color: Colors.fgMuted
                }
            }
        }
    }
}
