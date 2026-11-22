pragma Singleton
import Quickshell
import QtQuick

// Session switches that live in the shell. stayAwake drives an IdleInhibitor
// in the bar; it survives shell reloads (wallpaper changes).
Singleton {
    id: root
    property alias stayAwake: persist.stayAwake
    property bool locked: false // set by the lock screen

    PersistentProperties {
        id: persist
        reloadableId: "sessionState"
        property bool stayAwake: false
    }
}
