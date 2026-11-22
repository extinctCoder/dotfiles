import QtQuick
import qs.theme

// Mirrored bars: `up` above a center line, `down` below (e.g. download/upload).
// Scaled to the largest recent value; empty history = just the line.
Item {
    id: root
    property var up: []
    property var down: []
    property int count: 40
    readonly property real peak: Math.max(1, ...up, ...down)

    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Colors.border }
    Row {
        anchors.fill: parent
        spacing: 1
        Repeater {
            model: root.count
            Item {
                required property int index
                readonly property int i: index - (root.count - root.up.length)
                width: (root.width - root.count) / root.count
                height: root.height
                Rectangle {
                    anchors { bottom: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
                    width: parent.width
                    height: parent.i >= 0 ? root.height / 2 * (root.up[parent.i] ?? 0) / root.peak : 0
                    color: Colors.accent
                }
                Rectangle {
                    anchors { top: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
                    width: parent.width
                    height: parent.i >= 0 ? root.height / 2 * (root.down[parent.i] ?? 0) / root.peak : 0
                    color: Colors.fgMuted
                }
            }
        }
    }
}
