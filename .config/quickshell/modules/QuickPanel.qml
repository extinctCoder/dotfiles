import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Super+A or the bell: quick settings on top, notification history below.
LazyLoader {
    id: root
    active: Panels.open === "quick"

    component Toggle: Rectangle {
        id: t
        property string icon: ""
        property string label: ""
        property bool on: false
        signal toggled()
        Layout.fillWidth: true
        implicitHeight: Style.rowHeight * 2
        color: on ? Colors.accent : "transparent"
        border { width: Style.border; color: on ? Colors.accent : Colors.border }
        Column {
            anchors.centerIn: parent
            Mono { anchors.horizontalCenter: parent.horizontalCenter; text: t.icon; color: t.on ? Colors.accentFg : Colors.accent; font.pixelSize: Style.fontLg }
            Mono { anchors.horizontalCenter: parent.horizontalCenter; text: t.label; color: t.on ? Colors.accentFg : Colors.fg; font.pixelSize: Style.fontSm }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-quick"

        Component.onCompleted: { Notifs.markRead(); Wifi.refresh(); Sunset.refresh(); Brightness.refresh(); }

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: panel
            anchors { top: parent.top; right: parent.right; topMargin: Style.barHeight + Style.pad; rightMargin: Style.pad }
            width: 400
            height: Math.min(parent.height - Style.barHeight - Style.pad * 2, col.implicitHeight + Style.padLg * 2)
            color: Colors.panel
            border { width: Style.border; color: Colors.border }

            MouseArea { anchors.fill: parent }
            Item { focus: true; Component.onCompleted: forceActiveFocus(); Keys.onEscapePressed: Panels.close() }

            ColumnLayout {
                id: col
                anchors { fill: parent; margins: Style.padLg }
                spacing: Style.pad

                Mono { text: "quick settings"; color: Colors.fgMuted }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: Style.gap
                    rowSpacing: Style.gap

                    Toggle { icon: Wifi.radio ? Icons.wifi : Icons.wifiOff; label: "wi-fi"; on: Wifi.radio; onToggled: Wifi.setRadio(!Wifi.radio) }
                    Toggle {
                        readonly property var adapter: Bluetooth.defaultAdapter
                        icon: adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                        label: "bluetooth"
                        on: adapter?.enabled ?? false
                        onToggled: if (adapter) adapter.enabled = !adapter.enabled
                    }
                    Toggle { icon: Icons.night; label: "night light"; on: Sunset.on; onToggled: Sunset.toggle() }
                    Toggle { icon: Icons.bellOff; label: "do not disturb"; on: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                    Toggle { icon: Icons.coffee; label: "stay awake"; on: Session.stayAwake; onToggled: Session.stayAwake = !Session.stayAwake }
                }

                Slider {
                    Layout.fillWidth: true
                    icon: Audio.muted ? Icons.volumeOff : Icons.volume
                    value: Audio.ready ? Audio.volume / 100 : 0
                    label: Audio.ready ? Audio.volume + "%" : "--"
                    onMoved: v => Audio.setVolume(v)
                }
                Slider {
                    Layout.fillWidth: true
                    icon: Icons.brightness
                    value: Brightness.percent >= 0 ? Brightness.percent / 100 : 0
                    label: Brightness.percent >= 0 ? Brightness.percent + "%" : "--"
                    onMoved: v => Brightness.set(v * 100)
                }
                Slider {
                    Layout.fillWidth: true
                    icon: "Aa"
                    value: (TextSize.scale - 0.8) / 0.7
                    label: Math.round(TextSize.scale * 100) + "%"
                    onMoved: v => TextSize.set(0.8 + v * 0.7)
                }
                RowLayout {
                    spacing: Style.padLg
                    Mono { text: "power"; color: Colors.fgMuted }
                    Repeater {
                        model: [{ label: "eco", p: PowerProfile.PowerSaver }, { label: "bal", p: PowerProfile.Balanced }, { label: "perf", p: PowerProfile.Performance }]
                        MonoButton {
                            required property var modelData
                            readonly property bool current: Power.profile === modelData.p
                            visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                            text: current ? "[" + modelData.label + "]" : " " + modelData.label + " "
                            color: current ? Colors.accent : Colors.fgMuted
                            onClicked: PowerProfiles.profile = modelData.p
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
                RowLayout {
                    Layout.fillWidth: true
                    Mono { text: "notifications (" + Notifs.history.length + ")"; color: Colors.fgMuted; Layout.fillWidth: true }
                    MonoButton { visible: Notifs.history.length > 0; text: "clear"; color: Colors.accent; onClicked: Notifs.clearHistory() }
                }
                Mono { visible: Notifs.history.length === 0; text: "[info] nothing new"; color: Colors.fgMuted }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Notifs.history.length ? Style.rowHeight * 2 : 0
                    implicitHeight: contentHeight
                    clip: true
                    spacing: Style.pad
                    model: Notifs.history
                    delegate: Column {
                        id: entry
                        required property var modelData
                        width: ListView.view.width
                        Mono {
                            width: parent.width
                            elide: Text.ElideRight
                            color: entry.modelData.critical ? Colors.alert : Colors.fg
                            text: entry.modelData.time + "  " + entry.modelData.app + ": " + entry.modelData.summary
                        }
                        Mono {
                            visible: entry.modelData.body !== ""
                            width: parent.width
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            color: Colors.fgMuted
                            font.pixelSize: Style.fontSm
                            text: entry.modelData.body
                        }
                    }
                }
            }
        }
    }
}
