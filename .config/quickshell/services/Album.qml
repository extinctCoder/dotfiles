pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The playing track's cover colors (4 prevalent colors), for the living core.
// ColorQuantizer reads local files only, so web covers (browsers, Spotify)
// are cached in ~/.cache/quickshell/art first.
Singleton {
    id: root
    readonly property string url: Media.active ? Media.artUrl : ""
    property string local: ""
    readonly property var colors: local !== "" ? quantizer.colors : []
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/art/"

    onUrlChanged: {
        if (url === "") { local = ""; return; }
        if (url.startsWith("file://")) { local = url; return; }
        fetch.target = cacheDir + Qt.md5(url);
        fetch.command = ["sh", "-c", '[ -s "$2" ] || { mkdir -p "$(dirname "$2")" && curl -sfL --max-time 10 -o "$2" "$1"; }', "sh", url, fetch.target];
        fetch.running = true;
    }

    Process {
        id: fetch
        property string target: ""
        onExited: code => root.local = code === 0 ? "file://" + target : ""
    }

    ColorQuantizer {
        id: quantizer
        source: root.local
        depth: 2 // 4 colors
        rescaleSize: 64
    }
}
