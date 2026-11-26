pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The media player the shell shows and controls (browser, mpv, Spotify...):
// the one playing; else the one that played most recently (so a paused video
// in the browser stays here and can be resumed); else any that can play.
//   present  there is such a player (paused or not): dashboard, cards, controls
//   active   it is playing right now: visualizer, the core's heartbeat, colors
Singleton {
    id: root
    readonly property var players: Array.from(Mpris.players.values)
    readonly property var playing: players.find(p => p.isPlaying) ?? null
    property var last: null // the player that played most recently
    onPlayingChanged: if (playing) last = playing

    readonly property var player: playing
        ?? (last !== null && players.includes(last) ? last : null)
        ?? players.find(p => p.canPlay)
        ?? null
    readonly property bool present: player !== null
    readonly property bool active: player !== null && player.isPlaying

    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.length ?? 0
    // what Lyrics recognized by ear (SongRec): { artist, title, album, cover } or null.
    // shown*: what the dashboard and cards show, the real names when known
    property var recognized: null
    readonly property string shownTitle: recognized?.title || title
    readonly property string shownArtist: recognized?.artist || artist
    readonly property string cover: recognized?.cover || artUrl
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0
    function toggle() { if (player) player.togglePlaying(); }
    function next() { if (player) player.next(); }
    function previous() { if (player) player.previous(); }

    // Mpris position is not live; poke it while playing
    Timer {
        running: root.active
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
