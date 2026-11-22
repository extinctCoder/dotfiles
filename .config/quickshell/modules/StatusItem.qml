import QtQuick
import qs.theme
import qs.services

// One bar item: icon + short value in the accent color. Click opens its popup.
Item {
    id: root
    property string icon: ""
    property string value: ""
    property color color: Colors.accent
    property string popup: ""
    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: Style.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.gap
        Mono { text: root.icon; color: root.color }
        Mono { text: root.value; color: root.color; visible: root.value !== "" }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popup !== "" ? Panels.toggle(root.popup) : root.clicked()
    }
}
