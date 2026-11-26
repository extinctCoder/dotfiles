pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Synced lyrics from LRCLIB (free, no key) for the playing track, following its
// real position.
//   1. Quick: the player's own names. LRCLIB, from strict to loose: exact match
//      (artist, title, album, length); search with cleaned names (browsers send
//      "Artist - Title (Official Video)" with the channel as the artist); free
//      text. Search hits must match the length: within 5 s, 20 s without album.
//   2. By ear, when that finds nothing while it plays: record ~11 s of what the
//      speakers play (not the microphone), recognize it with SongRec (Shazam),
//      then look up the recognized artist, title and album. Each track is
//      recognized once: the result is remembered in
//      ~/.cache/quickshell/lyrics-recognized.json. Media.recognized carries the
//      real names and cover for the dashboard and cards.
// No lyrics found = nothing shown.
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
    readonly property bool listening: recognizer.running
    // what it is doing or found, for the dashboard when there are no lyrics (also in qs log)
    property string status: ""
    function say(s) { status = s; console.log("lyrics: " + s + (key ? "  [" + key + "]" : "")); }
    readonly property bool canRecognize: hasSongrec

    property bool hasSongrec: true   // false once the recognizer reports songrec missing
    property bool pending: false     // the track changed during a lookup: look up again after it
    property string fetchingKey: ""  // the track the running lookup or recognition is for
    property bool tried: false       // recognition already tried for this track
    property bool wantRecognize: false // the quick lookup found nothing: recognize once it has exited
    property var query: ({ artist: "", title: "", album: "", length: "0", cleanArtist: "", cleanTitle: "" })
    property var cache: ({})         // track key -> { artist, title, album, cover } or { none: true }

    readonly property string script:
        'ua="dotfiles-quickshell (github.com/extinctCoder/dotfiles)"; api=https://lrclib.net/api; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" '
        + '--data-urlencode "album_name=$3" --data-urlencode "duration=$4" "$api/get") '
        + '&& { printf "GET %s\\n" "$r"; exit; }; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "artist_name=$5" --data-urlencode "track_name=$6" "$api/search") '
        + '&& [ "$r" != "[]" ] && { printf "SEARCH %s\\n" "$r"; exit; }; '
        + 'r=$(curl -sfG -A "$ua" --max-time 10 --data-urlencode "q=$5 $6" "$api/search") '
        + '&& printf "SEARCH %s\\n" "$r"'

    // Split "Artist - Title" only when it really is one: the part before the dash
    // is the artist (letters compared loosely: "acdcVEVO" ~ "AC/DC"), the artist
    // was a channel ("...VEVO", "... - Topic"), or there is no album (a browser).
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
    function guess(artist, title, album) {
        const loose = x => x.toLowerCase().replace(/vevo$/, "").replace(/[^a-z0-9]/g, "");
        let a = cleanArtist(artist), t = cleanTitle(title);
        const m = t.match(/^(.+?)\s+[-\u2013\u2014]\s+(.+)$/);
        const channel = a !== (artist || "").trim();
        if (m && (loose(m[1]) === loose(artist || "") || channel || !album)) { a = m[1].trim(); t = m[2].trim(); }
        return { artist: a, title: t };
    }
    function parse(lrc) {
        const out = [];
        for (const l of (lrc || "").split("\n")) {
            const m = l.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (m) out.push({ t: Number(m[1]) * 60 + Number(m[2]), text: m[3] });
        }
        return out.sort((a, b) => a.t - b.t);
    }
    readonly property var clean: guess(Media.artist, Media.title, Media.album)

    // Players announce a new track in pieces (browsers: title, then artist, then
    // length), so wait until it settles, then look up once with complete info.
    onKeyChanged: { lines = []; Media.recognized = null; tried = false; settle.restart(); }
    Component.onCompleted: settle.restart() // a song may already be playing (the shell reloads on every wallpaper change)
    Timer {
        id: settle
        interval: 700
        onTriggered: root.start()
    }
    // a paused track that found nothing gets recognized once it plays
    Connections {
        target: Media
        function onActiveChanged() { if (Media.active && root.lines.length === 0 && !root.tried && root.key !== "") root.recognize(); }
    }

    function start() {
        if (key === "") return;
        if (fetch.running || recognizer.running) { pending = true; return; }
        const known = cache[key];
        say("looking up");
        if (known && !known.none) { // recognized before: use the real names right away
            tried = true;
            Media.recognized = known;
            lookup(known.artist, known.title, known.album, known.artist, known.title);
        } else {
            if (known && known.none) tried = true; // Shazam didn't know it last time
            lookup(Media.artist, Media.title, Media.album, clean.artist, clean.title);
        }
    }
    function lookup(artist, title, album, cleanArtist, cleanTitle) {
        query = { artist: artist, title: title, album: album, length: String(Math.round(Media.length)), cleanArtist: cleanArtist, cleanTitle: cleanTitle };
        fetchingKey = key;
        fetch.running = true;
    }
    function recognize() {
        if (!hasSongrec || tried || key === "" || fetch.running || recognizer.running) return;
        tried = true;
        fetchingKey = key;
        say("identifying the song by ear…");
        recognizer.running = true;
    }
    // after a lookup or recognition exits: a changed track starts over; else a
    // quick lookup that found nothing goes on to recognition
    function afterRun() {
        if (pending) { pending = false; wantRecognize = false; settle.restart(); return; }
        if (wantRecognize && !fetch.running && !recognizer.running) { wantRecognize = false; recognize(); }
    }
    function remember(k, value) {
        const c = Object.assign({}, cache);
        c[k] = value;
        const keys = Object.keys(c);
        for (const old of keys.slice(0, Math.max(0, keys.length - 500))) delete c[old]; // keep the last 500
        cache = c;
        cacheFile.setText(JSON.stringify(c));
    }

    FileView {
        id: cacheFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/lyrics-recognized.json"
        printErrors: false // missing until the first recognition
        atomicWrites: true
        onLoaded: { try { root.cache = JSON.parse(text()) || {}; } catch (e) { root.cache = {}; } }
    }

    Process {
        id: fetch
        // printf, not echo: echo may turn the "\n" escapes inside the JSON into real line breaks
        command: ["sh", "-c", root.script, "sh", root.query.artist, root.query.title, root.query.album, root.query.length,
            root.query.cleanArtist, root.query.cleanTitle]
        onExited: root.afterRun()
        stdout: StdioCollector {
            onStreamFinished: {
                let found = [], why = "lrclib has nothing for it";
                try {
                    if (text.startsWith("GET ")) {
                        found = root.parse(JSON.parse(text.slice(4)).syncedLyrics);
                    } else if (text.startsWith("SEARCH ")) {
                        const hits = JSON.parse(text.slice(7)).filter(h => h.syncedLyrics);
                        hits.sort((a, b) => Math.abs(a.duration - Media.length) - Math.abs(b.duration - Media.length));
                        // the player's album decides: none = likely a video (intros, outros), even
                        // when the names came from recognition (the length is still the video's)
                        const tolerance = Media.album === "" ? 20 : 5;
                        found = hits.length && Math.abs(hits[0].duration - Media.length) <= tolerance ? root.parse(hits[0].syncedLyrics) : [];
                        if (hits.length && !found.length)
                            why = "lrclib's lyrics are for a " + Math.round(hits[0].duration) + " s version, this one is " + Math.round(Media.length) + " s (timing would be off)";
                        else if (!hits.length && text.length > 9) why = "lrclib has it, but without synced lyrics";
                    }
                } catch (e) { found = []; why = "lrclib didn't answer"; }
                if (root.fetchingKey !== root.key) return; // track changed meanwhile (a new lookup follows)
                root.lines = found;
                const named = Media.recognized ? Media.recognized.artist + " – " + Media.recognized.title + ": " : "";
                if (found.length) root.say(named + "synced lyrics found (" + found.length + " lines)");
                else if (root.tried || !root.hasSongrec) root.say(named + why + (root.hasSongrec ? "" : " · install songrec to identify songs by ear"));
                else if (!Media.active) root.say(why + " · will identify it by ear once it plays");
                else root.say(why + " · identifying it by ear next");
                root.wantRecognize = found.length === 0 && Media.active;
                if (!fetch.running) root.afterRun(); // exited before its output was read
            }
        }
    }

    // ~11 s of what the speakers play (the output's monitor, never the microphone),
    // 16 kHz mono (what SongRec uses anyway), then Shazam's answer as JSON.
    // Exit 127: songrec or pw-record isn't installed.
    Process {
        id: recognizer
        command: ["sh", "-c",
            'command -v songrec >/dev/null && command -v pw-record >/dev/null || exit 127; '
            + 'mkdir -p "$HOME/.cache/quickshell"; tmp=$(mktemp --suffix=.wav); '
            + 'timeout -s INT 11 pw-record --rate 16000 --channels 1 -P \'{ "stream.capture.sink": true, "node.name": "lyrics-listener", "media.name": "identifying the song" }\' "$tmp" >/dev/null 2>&1; '
            + 'songrec audio-file-to-recognized-song "$tmp" 2>/dev/null; rc=$?; rm -f "$tmp"; exit $rc']
        onExited: code => {
            if (code === 127) { root.hasSongrec = false; root.say("songrec isn't installed: can't identify songs by ear"); }
            root.afterRun();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") { // songrec missing (said on exit), or no network / no sound: try again on the next track
                    if (root.hasSongrec) root.say("couldn't reach Shazam or heard no sound");
                    return;
                }
                let song = null;
                try {
                    const t = JSON.parse(text).track;
                    if (t && t.title) {
                        let album = "";
                        for (const sec of t.sections || []) {
                            if (sec.type !== "SONG") continue;
                            for (const m of sec.metadata || []) if (m.title === "Album") album = m.text || "";
                            break;
                        }
                        song = { artist: t.subtitle || "", title: t.title, album: album, cover: t.images?.coverart || "" };
                    }
                } catch (e) { return; }
                const k = root.fetchingKey;
                root.remember(k, song ?? { none: true });
                if (k !== root.key) return;
                if (!song) { root.say("Shazam doesn't know this one"); return; }
                root.say("identified: " + song.artist + " – " + song.title + " · looking up its lyrics");
                Media.recognized = song;
                root.lookup(song.artist, song.title, song.album, song.artist, song.title);
            }
        }
    }
}
