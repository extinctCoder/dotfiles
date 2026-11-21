import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Bottom-left desktop widget, under your windows, only while something plays.
PanelWindow {
    visible: Media.active
    anchors { bottom: true; left: true }
    margins { bottom: Style.padLg; left: Style.padLg }
    exclusiveZone: 0
    implicitWidth: 320
    implicitHeight: col.implicitHeight + Style.pad * 2
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-music"

    Rectangle {
        anchors.fill: parent
        color: Colors.panel
        border { width: Style.border; color: Colors.border }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
            spacing: Style.gap

            Mono { text: "now playing"; color: Colors.accent; font.pixelSize: Style.fontSm }
            Mono {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Media.title + " - " + Media.artist
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Colors.border
                Rectangle {
                    height: parent.height
                    width: parent.width * Media.progress
                    color: Colors.accent
                }
            }

            RowLayout {
                spacing: Style.padLg
                MonoButton { text: "prev"; color: Colors.fgMuted; onClicked: Media.previous() }
                MonoButton { text: "pause"; onClicked: Media.toggle() }
                MonoButton { text: "next"; color: Colors.fgMuted; onClicked: Media.next() }
            }
        }
    }
}
