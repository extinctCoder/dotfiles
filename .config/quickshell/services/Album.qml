pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The playing track's cover colors (4 prevalent colors), for the living core.
// ColorQuantizer reads local files only, so web covers (browsers, Spotify,
// recognized songs) are downloaded first: into the session's runtime folder
// ($XDG_RUNTIME_DIR, in memory), so nothing about what you play survives a
// reboot. forget() deletes them now.
Singleton {
    id: root
    readonly property string url: Media.active ? Media.cover : "" // the real album cover once recognized
    property string local: ""
    readonly property var colors: local !== "" ? quantizer.colors : []
    readonly property string cacheDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/art/"
    property int count: 0 // covers kept this session
    function forget() {
        local = "";
        wipe.command = ["sh", "-c", 'rm -rf "$1" "$HOME/.cache/quickshell/art"', "sh", cacheDir];
        wipe.running = true;
    }
    Process { id: wipe; onExited: root.count = 0 }
    Process {
        id: counter
        command: ["sh", "-c", 'ls "$1" 2>/dev/null | wc -l', "sh", root.cacheDir]
        stdout: StdioCollector { onStreamFinished: root.count = Number(text.trim()) || 0 }
    }
    // covers from before this moved to the runtime folder
    Component.onCompleted: { cleanup.running = true; counter.running = true; }
    Process { id: cleanup; command: ["sh", "-c", 'rm -rf "$HOME/.cache/quickshell/art"'] }

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
        onExited: code => { root.local = code === 0 ? "file://" + target : ""; counter.running = true; }
    }

    ColorQuantizer {
        id: quantizer
        source: root.local
        depth: 2 // 4 colors
        rescaleSize: 64
    }
}
