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
                source: Wall.path !== "" ? "file://" + Wall.path : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }
    }

    // save the path, then recolor everything from it
    Process { id: apply }
    readonly property string script:
        'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2" && matugen image -m dark "$1"'

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            apply.command = ["sh", "-c", script, "sh", path, Wall.stateFile];
            apply.running = true;
        }
        function next(): void {
            apply.command = ["sh", "-c",
                'f=$(find -L "$1" -type f | grep -iE "[.](jpe?g|png|webp)$" | shuf -n 1) && set -- "$f" "$2" && ' + script,
                "sh", Style.wallpaperDir, Wall.stateFile];
            apply.running = true;
        }
        function get(): string { return Wall.path; }
    }
}
