pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Zen bookmarks and history for the launcher. Zen locks places.sqlite while it
// runs, so this queries a copy (with its write-ahead log, so recent pages count).
// The profile link ~/.local/state/zen-profile is made by browser/zen-install.sh.
Singleton {
    id: root
    property string query: ""
    property var results: [] // launcher rows: bookmarks first, then by frecency

    readonly property string script:
        'db="$HOME/.local/state/zen-profile/places.sqlite"; [ -f "$db" ] || exit 0; '
        + 't=$(mktemp -d); cp "$db" "$t/p.sqlite"; [ -f "$db-wal" ] && cp "$db-wal" "$t/p.sqlite-wal"; '
        + "q=$(printf '%s' \"$1\" | sed \"s/'/''/g\"); "
        + 'sqlite3 -separator "$(printf \'\\t\')" "$t/p.sqlite" "'
        + "SELECT COALESCE(NULLIF(MAX(b.title), ''), p.title, p.url), p.url, MAX(b.id IS NOT NULL) "
        + "FROM moz_places p LEFT JOIN moz_bookmarks b ON b.fk = p.id "
        + "WHERE p.hidden = 0 AND (p.title LIKE '%$q%' OR p.url LIKE '%$q%' OR b.title LIKE '%$q%') "
        + "GROUP BY p.id ORDER BY MAX(b.id IS NOT NULL) DESC, p.frecency DESC LIMIT 8"
        + '"; rm -rf "$t"'

    onQueryChanged: { if (query.length < 2) results = []; else debounce.restart(); }
    Timer { id: debounce; interval: 200; onTriggered: { search.running = false; search.running = true; } }

    Process {
        id: search
        command: ["sh", "-c", root.script, "sh", root.query]
        stdout: StdioCollector {
            onStreamFinished: root.results = text.split("\n").filter(l => l).map(l => {
                const f = l.split("\t");
                const bookmark = f[2] === "1";
                return {
                    kind: "web", title: f[0], sub: (f[1].match(/^\w+:\/\/([^/]+)/) || [, f[1]])[1],
                    glyph: bookmark ? Icons.bookmark : Icons.history,
                    run: () => Quickshell.execDetached(["xdg-open", f[1]])
                };
            })
        }
    }
}
