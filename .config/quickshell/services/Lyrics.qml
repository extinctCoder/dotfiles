pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Synced lyrics from LRCLIB (free, no key) for the playing track, following its
// real position. Lookup, from strict to loose:
//   1. exact match with the player's artist, title, album and length
//   2. search with cleaned names (browsers send "Artist - Title (Official Video)"
//      with the channel, e.g. "acdcVEVO", as the artist)
//   3. free-text search "artist title"
// Search hits must match the length: within 5 s, or 20 s without an album
// (videos have intros). No lyrics found = nothing shown.
Singleton {
    id: root
    property var lines: []   // [{ t: seconds, text }]
    readonly property string key: Media.present ? Media.artist + "|" + Media.title : ""
    readonly property int index: {
        const p = Media.position;
        let i = -1;
        for (let k = 0; k < lines.length; k++) { if (lines[k].t <= p) i = k; else break; }
        return i;
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    readonly property string previous: index > 0 ? lines[index - 1].text : ""

    readonly property string script:
        'ua="dotfiles-quickshell (github.com/extinctCoder/dotfiles)"; api=https://lrclib.net/api; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" '
        + '--data-urlencode "album_name=$3" --data-urlencode "duration=$4" "$api/get") '
        + '&& { printf "GET %s\\n" "$r"; exit; }; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$5" --data-urlencode "track_name=$6" "$api/search") '
        + '&& [ "$r" != "[]" ] && { printf "SEARCH %s\\n" "$r"; exit; }; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "q=$5 $6" "$api/search") '
        + '&& printf "SEARCH %s\\n" "$r"'

    // Players announce a new track in pieces (browsers: title, then artist, then
    // length), so wait until it settles, then look up once with complete info.
    // A change during a lookup runs another one afterwards (its result is
    // stale and dropped), instead of being lost.
    property bool pending: false
    property string fetchingKey: "" // the track the running lookup is for
    onKeyChanged: { lines = []; settle.restart(); }
    Component.onCompleted: settle.restart() // a song may already be playing (the shell reloads on every wallpaper change)
    Timer {
        id: settle
        interval: 700
        onTriggered: {
            if (root.key === "") return;
            if (fetch.running) { root.pending = true; return; }
            root.fetchingKey = root.key;
            fetch.running = true;
        }
    }

    function cleanTitle(t) {
        return (t || "")
            .replace(/\s*[(\[][^)\]]*\b(official|video|audio|lyrics?|visuali[sz]er|hd|4k|hq|remaster(ed)?|mv|m\/v|live|explicit|clean|feat|ft)\b[^)\]]*[)\]]/gi, "")
            .replace(/\s*\|.*$/, "")
            .replace(/\s+[-\u2013]\s+(\d{4}\s+)?remaster(ed)?\b.*$/i, "")
            .replace(/\s+(ft\.?|feat\.?)\s.*$/i, "")
            .trim();
    }
    function cleanArtist(a) {
        return (a || "").replace(/vevo$/i, "").replace(/\s*-\s*topic$/i, "").replace(/\s*official$/i, "").trim();
    }
    // Split "Artist - Title" only when it really is one: the part before the dash
    // is the artist (letters compared loosely: "acdcVEVO" ~ "AC/DC"), the artist
    // was a channel ("...VEVO", "... - Topic"), or there is no album (a browser).
    function guess(artist, title, album) {
        const loose = x => x.toLowerCase().replace(/vevo$/, "").replace(/[^a-z0-9]/g, "");
        let a = cleanArtist(artist), t = cleanTitle(title);
        const m = t.match(/^(.+?)\s+[-\u2013\u2014]\s+(.+)$/);
        const channel = a !== (artist || "").trim();
        if (m && (loose(m[1]) === loose(artist || "") || channel || !album)) { a = m[1].trim(); t = m[2].trim(); }
        return { artist: a, title: t };
    }
    readonly property var clean: guess(Media.artist, Media.title, Media.album)

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
        command: ["sh", "-c", root.script, "sh", Media.artist, Media.title, Media.album, String(Math.round(Media.length)),
            root.clean.artist, root.clean.title]
        onExited: if (root.pending) { root.pending = false; settle.restart(); }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.startsWith("GET ")) {
                        root.lines = root.parse(JSON.parse(text.slice(4)).syncedLyrics);
                    } else if (text.startsWith("SEARCH ")) {
                        const hits = JSON.parse(text.slice(7)).filter(h => h.syncedLyrics);
                        hits.sort((a, b) => Math.abs(a.duration - Media.length) - Math.abs(b.duration - Media.length));
                        const tolerance = Media.album === "" ? 20 : 5; // no album = likely a video
                        root.lines = hits.length && Math.abs(hits[0].duration - Media.length) <= tolerance ? root.parse(hits[0].syncedLyrics) : [];
                    }
                } catch (e) { root.lines = []; }
                if (root.fetchingKey !== root.key) root.lines = []; // track changed meanwhile (a new lookup follows)
            }
        }
    }
}
