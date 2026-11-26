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
//      then look up the recognized artist, title and album. Only a fingerprint
//      goes to Shazam. Switch it off with byEar (quick settings, audio).
// Privacy: identified songs are kept in memory only (they survive shell reloads,
// not a reboot; the last 50), the log never names tracks, forget() clears them
// now. Media.recognized carries the real names, cover and details.
// Without synced lyrics, plain lyrics are shown (marked as not synced).
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
    // say(what the dashboard shows, what the log gets): the log never names the track
    function say(s, log) { status = s; console.log("lyrics: " + (log ?? s)); }
    property string plain: ""          // plain lyrics, when no synced version exists
    readonly property string source: Media.recognized?.by === "ear" ? "ear" : "player" // where the names came from
    readonly property int remembered: Object.keys(cache || {}).filter(k => !cache[k].none).length

    // listening by ear on/off: a setting (kept in ~/.local/state), not listening data
    property bool byEar: true
    function setByEar(on) { byEar = on; byEarFile.setText(on ? "on\n" : "off\n"); }
    FileView {
        id: byEarFile
        path: Quickshell.env("HOME") + "/.local/state/lyrics-by-ear"
        printErrors: false // missing = on
        onLoaded: root.byEar = text().trim() !== "off"
    }
    // forget now: identified songs (memory) and covers (Album)
    function forget() {
        cache = {};
        memory.cacheJson = "{}";
        Media.recognized = null;
        Album.forget();
        say("forgot identified songs and covers");
    }
    readonly property bool canRecognize: hasSongrec

    property bool hasSongrec: true   // false once the recognizer reports songrec missing
    property bool pending: false     // the track changed during a lookup: look up again after it
    property string fetchingKey: ""  // the track the running lookup or recognition is for
    property bool tried: false       // recognition already tried for this track
    property bool wantRecognize: false // the quick lookup found nothing: recognize once it has exited
    property bool missed: false        // the quick lookup ran for this track and found nothing
    property bool retried: false       // one more try by ear, 30 s later, after Shazam missed
    property var query: ({ artist: "", title: "", album: "", length: "0", cleanArtist: "", cleanTitle: "" })
    // track key -> { artist, title, album, year, genre, label, url, cover } or { none: true }
    property var cache: ({})
    PersistentProperties { // memory only: survives shell reloads (wallpaper changes), not a reboot.
        id: memory        // JSON text: a list or object would arrive undefined after a reload
        reloadableId: "lyricsMemory"
        property string cacheJson: "{}"
        onLoaded: { try { root.cache = JSON.parse(cacheJson) || {}; } catch (e) { root.cache = {}; } }
    }

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
    onKeyChanged: { lines = []; plain = ""; waitingShort = false; Media.recognized = null; tried = false; missed = false; retried = false; retry.stop(); settle.restart(); }
    Component.onCompleted: settle.restart() // a song may already be playing (the shell reloads on every wallpaper change)
    Timer {
        id: settle
        interval: 700
        onTriggered: root.start()
    }
    // a paused track that found nothing gets recognized once it plays
    Connections {
        target: Media
        function onActiveChanged() { if (Media.active && root.missed && !root.tried && root.key !== "") root.recognize(); }
    }

    property bool waitingShort: false // a track under 30 s (a video ad?): wait for the real one
    Connections {
        target: Media
        function onLengthChanged() { if (root.waitingShort && Media.length >= 30) { root.waitingShort = false; settle.restart(); } }
    }
    function start() {
        if (key === "") return;
        if (fetch.running || recognizer.running || details.running) { pending = true; return; }
        if (Media.length > 0 && Media.length < 30) { // 0 = unknown: look it up anyway (streams never say)
            waitingShort = true;
            say("waiting: " + Math.round(Media.length) + " s is too short for a song (an ad?)");
            return;
        }
        waitingShort = false;
        const known = (cache || {})[key];
        say("looking up");
        if (known && !known.none) { // known from before: use the real names right away
            if (known.by === "ear") tried = true;
            Media.recognized = known;
            lookup(known.artist, known.title, known.album, known.artist, known.title);
        } else {
            if (known && known.none) tried = true; // Shazam missed it earlier this session
            lookup(Media.artist, Media.title, Media.album, clean.artist, clean.title);
        }
    }
    function lookup(artist, title, album, cleanArtist, cleanTitle) {
        query = { artist: artist, title: title, album: album, length: String(Math.round(Media.length)), cleanArtist: cleanArtist, cleanTitle: cleanTitle };
        fetchingKey = key;
        fetch.running = true;
    }
    function recognize() {
        if (!byEar || !hasSongrec || tried || key === "" || fetch.running || recognizer.running) return;
        tried = true;
        fetchingKey = key;
        say("identifying the song by ear…");
        recognizer.running = true;
    }
    // after a lookup or recognition exits: a changed track starts over; else a
    // quick lookup that found nothing goes on to recognition
    function afterRun() {
        if (pending) { pending = false; wantRecognize = false; wantDetails = false; settle.restart(); return; }
        if (wantDetails && !fetch.running && !details.running) { wantDetails = false; lookUpDetails(); }
        if (wantRecognize && !fetch.running && !recognizer.running) { wantRecognize = false; recognize(); }
    }
    // Identified songs are written to disk; misses stay in memory only (a sample can
    // be unlucky: silence, an intro, an ad), so they are tried again next session.
    function remember(k, value) {
        const c = Object.assign({}, cache || {});
        delete c[k];
        c[k] = value; // newest last
        const keys = Object.keys(c);
        for (const old of keys.slice(0, Math.max(0, keys.length - 50))) delete c[old]; // the last 50
        cache = c;
        memory.cacheJson = JSON.stringify(c);
    }
    // after a miss: one more try by ear, 30 s further into the song
    Timer {
        id: retry
        interval: 30000
        onTriggered: {
            if (root.lines.length > 0 || root.retried || root.key === "") return;
            root.retried = true;
            root.tried = false;
            if (Media.active) root.recognize(); else root.missed = true; // tries when it plays
        }
    }

    // the earlier version kept identified songs on disk: remove that file
    Process { running: true; command: ["sh", "-c", 'rm -f "$HOME/.cache/quickshell/lyrics-recognized.json"'] }

    Process {
        id: fetch
        // printf, not echo: echo may turn the "\n" escapes inside the JSON into real line breaks
        command: ["sh", "-c", root.script, "sh", root.query.artist, root.query.title, root.query.album, root.query.length,
            root.query.cleanArtist, root.query.cleanTitle]
        onExited: root.afterRun()
        stdout: StdioCollector {
            onStreamFinished: {
                let found = [], plain = "", why = "lrclib has nothing for it";
                try {
                    if (text.startsWith("GET ")) {
                        const hit = JSON.parse(text.slice(4));
                        found = root.parse(hit.syncedLyrics);
                        if (!found.length) plain = hit.plainLyrics || "";
                    } else if (text.startsWith("SEARCH ")) {
                        const hits = JSON.parse(text.slice(7));
                        hits.sort((a, b) => Math.abs(a.duration - Media.length) - Math.abs(b.duration - Media.length));
                        // the player's album decides: none = likely a video (intros, outros), even
                        // when the names came from recognition (the length is still the video's)
                        const tolerance = Media.album === "" ? 20 : 5;
                        const near = hits.filter(h => Math.abs(h.duration - Media.length) <= tolerance);
                        const synced = near.find(h => h.syncedLyrics);
                        if (synced) found = root.parse(synced.syncedLyrics);
                        else plain = near.find(h => h.plainLyrics)?.plainLyrics ?? "";
                        const other = hits.find(h => h.syncedLyrics);
                        if (!found.length && !plain && other)
                            why = "lrclib's lyrics are for a " + Math.round(other.duration) + " s version, this one is " + Math.round(Media.length) + " s (timing would be off)";
                    }
                } catch (e) { found = []; plain = ""; why = "lrclib didn't answer"; }
                if (root.fetchingKey !== root.key) return; // track changed meanwhile (a new lookup follows)
                root.lines = found;
                root.plain = plain;
                root.missed = found.length === 0 && plain === "";
                const named = Media.recognized ? Media.recognized.artist + " – " + Media.recognized.title + ": " : "";
                if (found.length) root.say(named + "synced lyrics found (" + found.length + " lines)", "synced lyrics found (" + found.length + " lines)");
                else if (plain) root.say(named + "plain lyrics only (not synced)", "plain lyrics only (not synced)");
                else if (root.tried || !root.hasSongrec || !root.byEar) {
                    const tail = !root.byEar ? " · listening by ear is off" : root.hasSongrec ? "" : " · install songrec to identify songs by ear";
                    root.say(named + why + tail, why + tail);
                }
                else if (!Media.active) root.say(why + " · will identify it by ear once it plays");
                else root.say(why + " · identifying it by ear next");
                root.wantRecognize = found.length === 0 && plain === "" && Media.active;
                const listensNext = root.wantRecognize && root.byEar && root.hasSongrec && !root.tried;
                if (Media.recognized === null && !listensNext) root.wantDetails = true;
                if (!fetch.running) root.afterRun(); // exited before its output was read
            }
        }
    }

    // Album details by name (the quick way): one iTunes Search API request with
    // the cleaned artist and title (no key; ~20 requests a minute allowed, one per
    // new song here). Album, year, genre, a 600 px cover and a link. Without a match,
    // the cleaned names still replace the video's. Remembered like recognitions.
    property bool wantDetails: false
    function lookUpDetails() {
        if (key === "" || Media.recognized !== null) return;
        fetchingKey = key;
        details.query = { artist: clean.artist, title: clean.title };
        details.running = true;
    }
    function loose(x) { return (x || "").toLowerCase().replace(/&/g, "and").replace(/[^a-z0-9]/g, ""); }
    Process {
        id: details
        property var query: ({ artist: "", title: "" })
        command: ["curl", "-sfG", "--max-time", "10", "--data-urlencode", "term=" + query.artist + " " + query.title,
            "--data-urlencode", "entity=song", "--data-urlencode", "limit=10", "https://itunes.apple.com/search"]
        onExited: root.afterRun()
        stdout: StdioCollector {
            onStreamFinished: {
                const k = root.fetchingKey, q = details.query;
                let song = { by: "names", artist: q.artist, title: q.title }; // at least the cleaned names
                try {
                    const a = root.loose(q.artist), t = root.loose(q.title);
                    const hits = (JSON.parse(text).results || []).filter(r => {
                        const ra = root.loose(r.artistName), rt = root.loose(r.trackName);
                        return (ra === a || ra.includes(a) || a.includes(ra)) && rt.startsWith(t);
                    });
                    hits.sort((x, y) => Math.abs(x.trackTimeMillis / 1000 - Media.length) - Math.abs(y.trackTimeMillis / 1000 - Media.length));
                    const r = hits[0];
                    if (r) song = {
                        by: "names", artist: r.artistName, title: r.trackName, album: r.collectionName || "",
                        year: (r.releaseDate || "").slice(0, 4), genre: r.primaryGenreName || "", label: "",
                        url: r.trackViewUrl || "",
                        cover: (r.artworkUrl100 || "").replace("100x100", "600x600") // undocumented size; else stays 100 px
                    };
                } catch (e) {}
                if (k !== root.key) return;
                root.remember(k, song);
                Media.recognized = song;
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
                        let album = "", year = "", label = "";
                        for (const sec of t.sections || []) {
                            if (sec.type !== "SONG") continue;
                            for (const m of sec.metadata || []) {
                                if (m.title === "Album") album = m.text || "";
                                else if (m.title === "Released") year = m.text || "";
                                else if (m.title === "Label") label = m.text || "";
                            }
                            break;
                        }
                        song = { by: "ear", artist: t.subtitle || "", title: t.title, album: album, year: year, label: label,
                            genre: t.genres?.primary || "", url: t.url || "", cover: t.images?.coverart || "" };
                    }
                } catch (e) { return; }
                const k = root.fetchingKey;
                root.remember(k, song ?? { none: true });
                if (k !== root.key) return;
                if (!song) {
                    root.say(root.retried ? "Shazam doesn't know this one" : "Shazam didn't recognize it · trying again in 30 s");
                    if (!root.retried) retry.restart();
                    return;
                }
                root.say("identified: " + song.artist + " – " + song.title + " · looking up its lyrics", "identified · looking up its lyrics");
                Media.recognized = song;
                root.lookup(song.artist, song.title, song.album, song.artist, song.title);
            }
        }
    }
}
