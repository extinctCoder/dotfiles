import QtQuick
import qs.theme
import qs.services

// The bar's center. Shows, by priority: a notification preview (4 s), a volume
// or brightness level (1.5 s), the playing song (click: play/pause), else the
// focused window title. Replaces the old volume popup and music card.
Item {
    id: root
    property int maxWidth: 520
    property string mode: "" // "notif" | "level" | "" (resting)
    property string levelIcon: ""
    property int levelValue: 0
    property string notifText: ""
    property bool notifCritical: false
    property bool ready: false // ignore the volume/brightness values reported at startup

    readonly property string resting: Media.active ? "media" : "title"
    readonly property string shown: mode !== "" ? mode : resting

    implicitWidth: Math.min(maxWidth, content.implicitWidth + (shown === "title" ? 0 : Style.padLg * 2))
    implicitHeight: Style.barHeight

    function showLevel(icon, value) {
        if (!ready) return;
        levelIcon = icon; levelValue = value; mode = "level"; levelTimer.restart();
    }
    function bar(v) { // 10-step text gauge, like the rest of the shell's log style
        const n = Math.max(0, Math.min(10, Math.round(v / 10)));
        return "#".repeat(n) + "-".repeat(10 - n);
    }

    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Timer { id: levelTimer; interval: 1500; onTriggered: if (root.mode === "level") root.mode = "" }
    Timer { id: notifTimer; interval: 4000; onTriggered: if (root.mode === "notif") root.mode = "" }

    Connections {
        target: Audio
        function onVolumeEvent() { root.showLevel(Audio.muted ? Icons.volumeOff : Icons.volume, Audio.muted ? 0 : Audio.volume); }
    }
    Connections {
        target: Brightness
        function onBrightnessEvent() { root.showLevel(Icons.brightness, Brightness.percent); }
    }
    Connections {
        target: Notifs
        function onNotified(text, critical) {
            root.notifText = text; root.notifCritical = critical; root.mode = "notif"; notifTimer.restart();
        }
    }

    Rectangle {
        anchors { fill: parent; topMargin: 3; bottomMargin: 3 }
        color: root.shown === "title" ? "transparent" : Colors.raised
        border { width: root.shown === "notif" && root.notifCritical ? Style.border : 0; color: Colors.alert }
    }

    Mono {
        id: content
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.maxWidth - Style.padLg * 2)
        elide: Text.ElideRight
        color: root.shown === "notif" && root.notifCritical ? Colors.alert : Colors.accent
        text: {
            switch (root.shown) {
            case "notif": return Icons.bell + "  " + root.notifText;
            case "level": return root.levelIcon + "  " + root.bar(root.levelValue) + "  " + root.levelValue + "%";
            case "media": return Icons.music + "  " + Media.title + (Media.artist ? " - " + Media.artist : "");
            default: return Hypr.windowTitle;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.shown === "media"
        cursorShape: Qt.PointingHandCursor
        onClicked: Media.toggle()
    }
}
