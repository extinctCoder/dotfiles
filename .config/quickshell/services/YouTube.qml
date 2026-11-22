pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// YouTube search for the launcher ("yt <words>"), played in mpv. yt-dlp's flat
// mode returns title, channel and length without opening each video, so it's fast.
Singleton {
    id: root
    property string query: ""
    property var results: []
    readonly property bool busy: search.running || debounce.running

    function play(url) { Quickshell.execDetached(["mpv", url]); }
    function length(s) {
        const n = Number(s);
        if (!isFinite(n) || n <= 0) return "live";
        const h = Math.floor(n / 3600), m = Math.floor(n % 3600 / 60), sec = Math.floor(n % 60);
        return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(sec).padStart(2, "0");
    }

    onQueryChanged: { if (query.length < 2) results = []; else debounce.restart(); }
    Timer { id: debounce; interval: 500; onTriggered: { search.running = false; search.running = true; } }

    Process {
        id: search
        command: ["yt-dlp", "--flat-playlist", "--no-warnings", "--print",
            "%(id)s\t%(title)s\t%(channel)s\t%(duration)s", "ytsearch8:" + root.query]
        stdout: StdioCollector {
            onStreamFinished: root.results = text.split("\n").filter(l => l).map(l => {
                const f = l.split("\t");
                const url = "https://www.youtube.com/watch?v=" + f[0];
                return {
                    kind: "yt", title: f[1], sub: (f[2] === "NA" ? "" : f[2] + " · ") + root.length(f[3]),
                    glyph: Icons.youtube, run: () => root.play(url)
                };
            })
        }
    }
}
