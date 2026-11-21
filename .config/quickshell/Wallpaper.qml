import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
    id: root
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

    // Save the path, then recolor everything from it.
    // --source-color-index 0: take the most dominant color. Without it, matugen 4
    // asks interactively when an image has several candidates, and with no
    // terminal (as here) it stops without writing any colors.
    // Each pick runs on its own, and a failure shows a notification.
    readonly property string script:
        'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2" && '
        + '{ matugen image -m dark --source-color-index 0 "$1" '
        + '|| notify-send -a wallpaper -u critical "colors failed" "run: matugen image -m dark --source-color-index 0 $1"; }'

    function run(args) {
        Quickshell.execDetached(["sh", "-c"].concat(args));
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.run([root.script, "sh", path, Wall.stateFile]);
        }
        function next(): void {
            root.run(['f=$(find -L "$1" -type f | grep -iE "[.](jpe?g|png|webp)$" | shuf -n 1) && set -- "$f" "$2" && ' + root.script,
                "sh", Style.wallpaperDir, Wall.stateFile]);
        }
        function get(): string { return Wall.path; }
    }
}
