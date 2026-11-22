pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Synced lyrics from LRCLIB (free, no key) for the playing track, following its
// real position. Exact match first (artist, title, album, duration), then search.
// No lyrics found = nothing shown.
Singleton {
    id: root
    property var lines: []   // [{ t: seconds, text }]
    readonly property string key: Media.active ? Media.artist + "|" + Media.title : ""
    readonly property int index: {
        const p = Media.position;
        let i = -1;
        for (let k = 0; k < lines.length; k++) { if (lines[k].t <= p) i = k; else break; }
        return i;
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    readonly property string previous: index > 0 ? lines[index - 1].text : ""

    readonly property string script:
        'ua="dotfiles-quickshell (github.com/extinctCoder/dotfiles)"; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" '
        + '--data-urlencode "album_name=$3" --data-urlencode "duration=$4" https://lrclib.net/api/get) '
        + '&& { printf "GET %s\\n" "$r"; exit; }; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" https://lrclib.net/api/search) '
        + '&& printf "SEARCH %s\\n" "$r"'

    onKeyChanged: { lines = []; if (key !== "") fetch.running = true; }

    function parse(lrc) {
        const out = [];
        for (const l of (lrc || "").split("\n")) {
            const m = l.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (m) out.push({ t: Number(m[1]) * 60 + Number(m[2]), text: m[3] });
        }
        return out.sort((a, b) => a.t - b.t);
    }

    Process {
        id: fetch
        // printf, not echo: echo may turn the "\n" escapes inside the JSON into real line breaks
        command: ["sh", "-c", root.script, "sh", Media.artist, Media.title, Media.album, String(Math.round(Media.length))]
        stdout: StdioCollector {
            onStreamFinished: {
                const want = root.key;
                try {
                    if (text.startsWith("GET ")) {
                        root.lines = root.parse(JSON.parse(text.slice(4)).syncedLyrics);
                    } else if (text.startsWith("SEARCH ")) {
                        const hits = JSON.parse(text.slice(7)).filter(h => h.syncedLyrics);
                        hits.sort((a, b) => Math.abs(a.duration - Media.length) - Math.abs(b.duration - Media.length));
                        root.lines = hits.length && Math.abs(hits[0].duration - Media.length) < 5 ? root.parse(hits[0].syncedLyrics) : [];
                    }
                } catch (e) { root.lines = []; }
                if (want !== root.key) root.lines = []; // track changed meanwhile
            }
        }
    }
}
