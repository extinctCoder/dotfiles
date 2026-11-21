import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root
    property bool shown: false
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null

    Connections {
        target: root.audio
        function onVolumeChanged() { root.shown = true; hide.restart(); }
        function onMutedChanged() { root.shown = true; hide.restart(); }
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
                        if (!root.audio) return "vol --";
                        if (root.audio.muted) return "vol [   muted  ] --";
                        const v = Math.round(root.audio.volume * 100);
                        const n = Math.max(0, Math.min(10, Math.round(v / 10)));
                        return "vol [" + "#".repeat(n) + "-".repeat(10 - n) + "] " + v + "%";
                    }
                }
            }
        }
    }
}
