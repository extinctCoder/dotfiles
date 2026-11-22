pragma Singleton
import Quickshell
import QtQuick

// Session switches that live in the shell. stayAwake drives an IdleInhibitor
// in the bar; it survives shell reloads (wallpaper changes).
Singleton {
    id: root
    property alias stayAwake: persist.stayAwake

    PersistentProperties {
        id: persist
        reloadableId: "sessionState"
        property bool stayAwake: false
    }
}
