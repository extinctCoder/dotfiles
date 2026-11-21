import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

// Super+W (or leader p): thumbnails of ~/Pictures/wallpapers.
// Arrows or H/J/K/L to move, Enter or click to apply and recolor.
LazyLoader {
    active: Panels.open === "picker"

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-picker"

        Component.onCompleted: Wall.scan() // re-scan the folder every time

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: box
            readonly property int cols: 4
            readonly property int cellW: 220
            readonly property int cellH: Math.round(cellW * 9 / 16)
            readonly property int rows: Math.max(1, Math.ceil(Wall.files.length / cols))

            anchors.centerIn: parent
            width: cols * grid.cellWidth + Style.pad * 2
            height: Math.min(parent.height * 0.8, header.implicitHeight + rows * grid.cellHeight + Style.pad * 3)
            color: Colors.panel
            border { width: Style.border; color: Colors.border }

            MouseArea { anchors.fill: parent }

            function apply(i) {
                const f = Wall.files[i];
                if (!f) return;
                Wall.set(f);
                Panels.close();
            }

            Mono {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: Style.pad }
                elide: Text.ElideRight
                color: Colors.accent
                font.pixelSize: Style.fontLg
                text: "wallpaper>  " + (Wall.files[grid.currentIndex]?.split("/").pop() ?? "")
            }

            Mono {
                anchors.centerIn: parent
                visible: Wall.files.length === 0
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
                model: Wall.files
                focus: true
                keyNavigationWraps: true

                Component.onCompleted: forceActiveFocus()
                onCountChanged: currentIndex = Math.max(0, Wall.files.indexOf(Wall.path))

                Keys.onEscapePressed: Panels.close()
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
