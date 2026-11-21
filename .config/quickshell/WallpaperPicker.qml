import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// Wallpaper picker: Super + W (or leader + p).
// Thumbnails of ~/Pictures/wallpapers; arrows or H/J/K/L to move,
// Enter or click to apply (sets the wallpaper and recolors everything).
Scope {
    id: root
    property bool open: false
    property var files: []

    function show() {
        list.running = true; // re-scan the folder every time
        open = true;
    }

    Process {
        id: list
        command: ["sh", "-c",
            'find -L "$1" -maxdepth 1 -type f | grep -iE "[.](jpe?g|png|webp)$" | sort',
            "sh", Style.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }

    IpcHandler {
        target: "picker"
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
            WlrLayershell.namespace: "quickshell-picker"

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Rectangle {
                id: box
                readonly property int cols: 4
                readonly property int cellW: 220
                readonly property int cellH: Math.round(cellW * 9 / 16)
                readonly property int rows: Math.max(1, Math.ceil(root.files.length / cols))

                anchors.centerIn: parent
                width: cols * grid.cellWidth + Style.pad * 2
                height: Math.min(parent.height * 0.8,
                    header.implicitHeight + rows * grid.cellHeight + Style.pad * 3)
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                MouseArea { anchors.fill: parent } // clicks inside stay inside

                function apply(i) {
                    const f = root.files[i];
                    if (!f) return;
                    Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "set", f]);
                    root.open = false;
                }

                Mono {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: Style.pad }
                    elide: Text.ElideRight
                    color: Colors.accent
                    font.pixelSize: Style.fontLg
                    text: "wallpaper>  " + (root.files[grid.currentIndex]?.split("/").pop() ?? "")
                }

                Mono {
                    anchors.centerIn: parent
                    visible: root.files.length === 0
                    color: Colors.fgMuted
                    text: "[info] no images in ~/Pictures/wallpapers"
                }

                GridView {
                    id: grid
                    anchors {
                        top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                        margins: Style.pad; topMargin: Style.gap
                    }
                    clip: true
                    cellWidth: box.cellW + Style.pad
                    cellHeight: box.cellH + Style.pad
                    model: root.files
                    focus: true
                    keyNavigationWraps: true

                    Component.onCompleted: forceActiveFocus()
                    onCountChanged: currentIndex = Math.max(0, root.files.indexOf(Wall.path))

                    Keys.onEscapePressed: root.open = false
                    Keys.onReturnPressed: box.apply(currentIndex)
                    Keys.onEnterPressed: box.apply(currentIndex)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_H) moveCurrentIndexLeft();
                        else if (event.key === Qt.Key_L) moveCurrentIndexRight();
                        else if (event.key === Qt.Key_K) moveCurrentIndexUp();
                        else if (event.key === Qt.Key_J) moveCurrentIndexDown();
                        else return;
                        event.accepted = true;
                    }

                    delegate: Item {
                        id: cell
                        required property string modelData
                        required property int index
                        readonly property bool current: GridView.isCurrentItem
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            width: box.cellW
                            height: box.cellH
                            color: Colors.bg
                            border {
                                width: cell.current ? 2 : Style.border
                                color: cell.current ? Colors.accent : Colors.border
                            }

                            Image {
                                anchors { fill: parent; margins: parent.border.width }
                                source: "file://" + cell.modelData
                                sourceSize.width: box.cellW * 2 // decode small, keeps it fast
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: grid.currentIndex = cell.index
                            onClicked: box.apply(cell.index)
                        }
                    }
                }
            }
        }
    }
}
