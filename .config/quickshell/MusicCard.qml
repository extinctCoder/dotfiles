import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    readonly property var player: Array.from(Mpris.players.values).find(p => p.isPlaying) ?? null

    PanelWindow {
        visible: root.player !== null
        anchors { bottom: true; left: true }
        margins { bottom: Style.padLg; left: Style.padLg }
        exclusiveZone: 0
        implicitWidth: 320
        implicitHeight: col.implicitHeight + Style.pad * 2
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-music"

        // Mpris position is not live; poke it once a second
        Timer {
            running: root.player !== null
            interval: 1000
            repeat: true
            onTriggered: root.player.positionChanged()
        }

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
                    text: (root.player?.trackTitle ?? "") + " - " + (root.player?.trackArtist ?? "")
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: Colors.border
                    Rectangle {
                        height: parent.height
                        color: Colors.accent
                        width: root.player && root.player.length > 0
                            ? parent.width * Math.min(1, root.player.position / root.player.length)
                            : 0
                    }
                }

                RowLayout {
                    spacing: Style.padLg
                    MonoButton { text: "prev"; color: Colors.fgMuted; onClicked: root.player.previous() }
                    MonoButton { text: "pause"; onClicked: root.player.togglePlaying() }
                    MonoButton { text: "next"; color: Colors.fgMuted; onClicked: root.player.next() }
                }
            }
        }
    }
}
