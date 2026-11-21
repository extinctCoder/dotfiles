import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

// Volume popup: shows whenever volume or mute changes. Click-through.
Scope {
    id: root
    property bool shown: false

    Connections {
        target: Audio
        function onVolumeEvent() { root.shown = true; hide.restart(); }
    }
    Timer { id: hide; interval: 1200; onTriggered: root.shown = false }

    LazyLoader {
        active: root.shown

        PanelWindow {
            anchors.bottom: true
            margins.bottom: 80
            exclusiveZone: 0
            implicitWidth: 240
            implicitHeight: Style.rowHeight + Style.pad
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osd"

            Rectangle {
                anchors.fill: parent
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                Mono {
                    anchors.centerIn: parent
                    text: {
                        if (!Audio.ready) return "vol --";
                        if (Audio.muted) return "vol [   muted  ] --";
                        const n = Math.max(0, Math.min(10, Math.round(Audio.volume / 10)));
                        return "vol [" + "#".repeat(n) + "-".repeat(10 - n) + "] " + Audio.volume + "%";
                    }
                }
            }
        }
    }
}
