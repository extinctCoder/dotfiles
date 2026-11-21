import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
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
                source: Colors.wallpaper !== "" ? "file://" + Colors.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }
    }

    Process { id: apply }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            apply.command = ["matugen", "image", "-m", "dark", path];
            apply.running = true;
        }
        function next(): void {
            apply.command = ["sh", "-c",
                'f=$(find "$1" -type f | grep -iE "[.](jpe?g|png|webp)$" | shuf -n 1) && matugen image -m dark "$f"',
                "sh", Style.wallpaperDir];
            apply.running = true;
        }
        function get(): string { return Colors.wallpaper; }
    }
}
