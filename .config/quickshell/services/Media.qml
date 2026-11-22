pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Whatever is playing right now (browser, mpv, Spotify...).
Singleton {
    id: root
    readonly property var player: Array.from(Mpris.players.values).find(p => p.isPlaying) ?? null
    readonly property bool active: player !== null
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.length ?? 0
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    function toggle() { if (player) player.togglePlaying(); }
    function next() { if (player) player.next(); }
    function previous() { if (player) player.previous(); }

    // Mpris position is not live; poke it once a second while playing
    Timer {
        running: root.active
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
