import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wallpaper"
        color: Colors.bg

        Image {
            anchors.fill: parent
            source: Wall.path !== "" ? "file://" + Wall.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }
}
