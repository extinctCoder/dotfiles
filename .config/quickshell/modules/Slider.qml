import QtQuick
import QtQuick.Layouts
import qs.theme

// Flat slider: icon, a 1-line track, value. Drag or click to set; emits moved(0..1).
RowLayout {
    id: root
    property string icon: ""
    property real value: 0 // 0..1
    property string label: Math.round(value * 100) + "%"
    signal moved(real v)
    spacing: Style.pad

    Mono { text: root.icon; color: Colors.accent; Layout.preferredWidth: Style.fontLg * 1.4 }
    Item {
        Layout.fillWidth: true
        implicitHeight: Style.rowHeight
        Rectangle {
            id: track
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 4
            color: Colors.border
            Rectangle { width: parent.width * Math.max(0, Math.min(1, root.value)); height: parent.height; color: Colors.accent }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
            onPressed: e => set(e.x)
            onPositionChanged: e => { if (pressed) set(e.x); }
        }
    }
    Mono { text: root.label; color: Colors.fgMuted; Layout.preferredWidth: Style.fontMd * 3.2; horizontalAlignment: Text.AlignRight }
}
