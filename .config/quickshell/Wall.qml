pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The current wallpaper path. Kept in ~/.local/state/wallpaper so it never
// depends on matugen; falls back to the path matugen writes into Colors.qml.
Singleton {
    id: root
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/wallpaper"
    property string path: Colors.wallpaper

    FileView {
        id: file
        path: root.stateFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = text().trim();
            if (p !== "") root.path = p;
        }
    }
}
