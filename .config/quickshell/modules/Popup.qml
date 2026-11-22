import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// A dropdown under a bar item. Open when Panels.open === name; clicking
// outside closes it (grabFocus). Children go into a padded column.
PopupWindow {
    id: root
    required property string name
    required property Item item
    property int popupWidth: 320
    default property alias content: col.data

    anchor.item: item
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Style.gap
    grabFocus: true
    visible: Panels.open === name
    onVisibleChanged: if (!visible && Panels.open === name) Panels.close()

    implicitWidth: popupWidth
    implicitHeight: col.implicitHeight + Style.padLg * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.panel
        border { width: Style.border; color: Colors.border }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.padLg }
            spacing: Style.pad
        }
    }
}
