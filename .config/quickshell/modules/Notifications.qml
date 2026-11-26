import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Events as cards, stacked under the right side of the bar. Each card leaves on
// its own; the thin bar along its bottom shows the time left (hover pauses it).
//   level         volume or brightness while it changes (one card, updated)
//   now playing   on a track change or play/pause: cover, title, controls
//   notification  app icon or image, text, inline reply where the app supports it.
//                 Left click: default action + close · right click: close ·
//                 Super+N clears all. Critical ones stay until handled.
PanelWindow {
    id: win
    readonly property bool showing: Notifs.any || level.shown || playing.shown
    visible: showing
    anchors { top: true; right: true }
    margins { top: Style.pad; right: Style.pad }
    exclusiveZone: 0
    implicitWidth: 380
    implicitHeight: stack.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"
    // keyboard only when a reply box is clicked; never steals focus otherwise
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // the audio and brightness services report their first values at startup
    // (and on every shell reload): don't show those as a level change
    property bool settled: false
    Timer { interval: 2000; running: true; onTriggered: win.settled = true }

    // a card: raised panel, 1px border, a timeout bar along the bottom
    component Card: Rectangle {
        id: card
        property int timeout: 5000       // ms; 0 = stays until handled
        property bool alert: false
        property real left: 1            // 1 → 0 as time runs out
        default property alias content: body.data
        signal timedOut()
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Style.pad * 2
        color: Colors.raised
        border { width: Style.border; color: card.alert ? Colors.alert : Colors.border }
        HoverHandler { id: cardHover }
        function restart() { left = 1; }
        Timer {
            interval: 50
            repeat: true
            running: card.timeout > 0 && !cardHover.hovered && card.visible
            onTriggered: { card.left -= 50 / card.timeout; if (card.left <= 0) card.timedOut(); }
        }
        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
            spacing: Style.gap
        }
        Rectangle {
            visible: card.timeout > 0
            anchors { left: parent.left; bottom: parent.bottom }
            width: parent.width * Math.max(0, card.left)
            height: 2
            color: card.alert ? Colors.alert : Colors.accent
        }
    }

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: Style.gap

        // ---- level: volume / brightness ----
        Card {
            id: level
            property bool shown: false
            property string kind: "volume"
            timeout: 1500
            visible: shown
            onTimedOut: shown = false
            function show(k) { if (!win.settled) return; kind = k; restart(); shown = true; }
            Connections {
                target: Audio
                function onVolumeEvent() { level.show("volume"); }
            }
            Connections {
                target: Brightness
                function onBrightnessEvent() { level.show("brightness"); }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.pad
                readonly property bool vol: level.kind === "volume"
                readonly property real value: vol ? (Audio.muted ? 0 : Audio.volume / 100) : Math.max(0, Brightness.percent) / 100
                Mono { text: parent.vol ? (Audio.muted ? Icons.volumeOff : Icons.volume) : Icons.brightness; color: Colors.accent }
                Rectangle {
                    Layout.fillWidth: true
                    height: 3
                    color: Colors.border
                    Rectangle { width: parent.width * parent.parent.value; height: parent.height; color: Colors.accent }
                }
                Mono { text: parent.vol && Audio.muted ? "muted" : Math.round(parent.value * 100) + "%"; color: Colors.accent }
            }
        }

        // ---- now playing ----
        Card {
            id: playing
            property bool shown: false
            timeout: 4000
            visible: shown && Media.active
            onTimedOut: shown = false
            Connections {
                target: Media
                function onTitleChanged() { if (Media.title !== "") { playing.restart(); playing.shown = true; } }
                function onActiveChanged() { if (Media.active) { playing.restart(); playing.shown = true; } }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.pad
                Rectangle {
                    implicitWidth: Style.rowHeight * 2
                    implicitHeight: Style.rowHeight * 2
                    color: Colors.panel
                    border { width: Style.border; color: Colors.border }
                    Image {
                        anchors { fill: parent; margins: Style.border }
                        source: Media.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Mono { text: Icons.music + " now playing"; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                    Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.title }
                    Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.artist; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                }
                MonoButton { text: Icons.previous; color: Colors.accent; onClicked: Media.previous() }
                MonoButton { text: Media.active ? Icons.pause : Icons.playIcon; color: Colors.accent; onClicked: Media.toggle() }
                MonoButton { text: Icons.next; color: Colors.accent; onClicked: Media.next() }
            }
        }

        // ---- notifications ----
        Repeater {
            model: Notifs.list
            Card {
                id: note
                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                alert: critical
                timeout: critical ? 0 : (modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000)
                onTimedOut: modelData.expire()
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTapped: (point, button) => Notifs.activate(note.modelData, button === Qt.LeftButton)
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.pad
                    IconImage { // the sender's image (a contact's photo)
                        visible: note.modelData.image !== ""
                        Layout.alignment: Qt.AlignTop
                        implicitSize: Style.rowHeight * 1.6
                        source: note.modelData.image
                    }
                    AppIcon { // else the app's icon
                        visible: note.modelData.image === ""
                        Layout.alignment: Qt.AlignTop
                        size: Style.fontLg
                        name: note.modelData.desktopEntry || note.modelData.appIcon || note.modelData.appName
                        color: note.critical ? Colors.alert : Colors.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Mono {
                            text: (note.modelData.appName || "app").toLowerCase() + " · now"
                            color: note.critical ? Colors.alert : Colors.fgMuted
                            font.pixelSize: Style.fontSm
                        }
                        Mono { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: Notifs.plain(note.modelData.summary) }
                        Mono {
                            visible: note.modelData.body !== ""
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: Colors.fgMuted
                            text: Notifs.plain(note.modelData.body)
                        }
                    }
                }
                // inline reply (chat apps that offer it)
                Rectangle {
                    visible: note.modelData.hasInlineReply
                    Layout.fillWidth: true
                    implicitHeight: Style.rowHeight
                    color: Colors.panel
                    border { width: Style.border; color: reply.activeFocus ? Colors.accent : Colors.border }
                    TextInput {
                        id: reply
                        anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colors.fg
                        font.family: Style.font
                        font.pixelSize: Style.fontMd
                        clip: true
                        onAccepted: if (text.trim() !== "") { note.modelData.sendInlineReply(text); note.modelData.dismiss(); }
                        Mono {
                            visible: reply.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.reply + " " + (note.modelData.inlineReplyPlaceholder || "reply")
                            color: Colors.fgMuted
                        }
                    }
                }
            }
        }
    }
}
