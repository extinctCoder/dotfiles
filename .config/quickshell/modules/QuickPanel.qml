import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Quick settings: one panel for the bar's status block, flush under the right
// side of the bar. Toggles on top, then sections; the status icon you clicked
// decides which section is unfolded (Panels.quickSection), the others stay one
// line each and unfold on click. Super+A opens it at notifications.
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
        implicitHeight: Style.rowHeight * 1.4
        color: "transparent"
        border { width: Style.border; color: on ? Colors.accent : Colors.border }
        RowLayout {
            anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
            spacing: Style.pad
            Mono { text: t.icon; color: t.on ? Colors.accent : Colors.fgMuted }
            Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: t.label; color: t.on ? Colors.accent : Colors.fgMuted; font.pixelSize: Style.fontSm }
        }
        TapHandler { onTapped: t.toggled() }
    }

    // a section: one line (icon, name, summary, arrow); unfolds its content
    component Section: ColumnLayout {
        id: sec
        required property string key
        property string icon: ""
        property string title: ""
        property string summary: ""
        readonly property bool unfolded: Panels.quickSection === key
        default property alias content: inner.data
        Layout.fillWidth: true
        spacing: 0
        Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.rowHeight * 1.3
            color: sec.unfolded ? Colors.panel : (secHover.hovered ? Colors.panel : "transparent")
            RowLayout {
                anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                spacing: Style.pad
                Mono { text: sec.icon; color: Colors.accent }
                Mono { text: sec.title }
                Mono { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; text: sec.summary; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                Mono { text: sec.unfolded ? Icons.chevronDown : Icons.chevron; color: Colors.fgMuted }
            }
            HoverHandler { id: secHover }
            TapHandler { onTapped: Panels.quickSection = sec.unfolded ? "" : sec.key }
        }
        ColumnLayout {
            id: inner
            visible: sec.unfolded
            Layout.fillWidth: true
            Layout.leftMargin: Style.pad
            Layout.rightMargin: Style.pad
            Layout.topMargin: Style.gap
            Layout.bottomMargin: Style.pad
            spacing: Style.gap
        }
    }

    // a clickable line inside a section
    component Line: Rectangle {
        id: ln
        property string text: ""
        property string side: ""
        property bool active: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: Style.rowHeight
        color: lnHover.hovered ? Colors.panel : "transparent"
        RowLayout {
            anchors { fill: parent; leftMargin: Style.gap; rightMargin: Style.gap }
            Mono { Layout.fillWidth: true; elide: Text.ElideRight; text: ln.text; color: ln.active ? Colors.accent : Colors.fg }
            Mono { text: ln.side; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
        }
        HoverHandler { id: lnHover }
        TapHandler { onTapped: ln.clicked() }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-quick"

        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property var source: Pipewire.defaultAudioSource
        PwObjectTracker { objects: [source] }

        Component.onCompleted: { Wifi.refresh(); Sunset.refresh(); Brightness.refresh(); if (Panels.quickSection === "notifs") Notifs.markRead(); }
        Connections { target: Panels; function onQuickSectionChanged() { if (Panels.quickSection === "notifs") Notifs.markRead(); } }

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: panel
            // flush under the right side of the bar, covering the bar's bottom line
            anchors { top: parent.top; right: parent.right; topMargin: Style.barHeight - Style.border }
            width: 420
            height: Math.min(parent.height - Style.barHeight, col.implicitHeight + Style.pad * 2 + hint.height)
            color: Colors.raised
            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Style.border; color: Colors.border }
            MouseArea { anchors.fill: parent }
            Item { focus: true; Component.onCompleted: forceActiveFocus(); Keys.onEscapePressed: Panels.close() }

            Flickable {
                anchors { fill: parent; margins: Style.pad; bottomMargin: hint.height + Style.pad }
                contentHeight: col.implicitHeight
                clip: true
                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: Style.pad

                    RowLayout {
                        Layout.fillWidth: true
                        Mono { text: Quickshell.env("USER"); Layout.fillWidth: true }
                        Mono { text: "up " + Sys.duration(Sys.uptime); color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                        Mono { visible: Battery.present; text: Battery.percent + "%"; color: Battery.low ? Colors.alert : Colors.accent }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Style.gap
                        rowSpacing: Style.gap
                        Toggle { icon: Wifi.radio ? Icons.wifi : Icons.wifiOff; label: Wifi.connected ? "wi-fi · " + Wifi.ssid : "wi-fi"; on: Wifi.radio; onToggled: Wifi.setRadio(!Wifi.radio) }
                        Toggle {
                            icon: adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                            label: "bluetooth"
                            on: adapter?.enabled ?? false
                            onToggled: if (adapter) adapter.enabled = !adapter.enabled
                        }
                        Toggle { icon: Icons.night; label: "night light"; on: Sunset.on; onToggled: Sunset.toggle() }
                        Toggle { icon: Icons.bellOff; label: "silent"; on: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                        Toggle { icon: Icons.coffee; label: "stay awake"; on: Session.stayAwake; onToggled: Session.stayAwake = !Session.stayAwake }
                        Toggle {
                            readonly property bool muted: source?.audio?.muted ?? false
                            icon: muted ? Icons.micOff : Icons.mic
                            label: muted ? "mic muted" : "mic"
                            on: !muted
                            onToggled: if (source?.audio) source.audio.muted = !source.audio.muted
                        }
                    }

                    Section {
                        key: "wifi"; icon: Icons.wifi; title: "wi-fi"
                        summary: !Wifi.radio ? "off" : Wifi.connected ? Wifi.ssid + " · " + Wifi.signal + "%" : "not connected"
                        Repeater {
                            model: Wifi.networks.slice(0, 8)
                            Line {
                                required property var modelData
                                text: modelData.ssid
                                side: modelData.signal + "%"
                                active: modelData.active
                                onClicked: { Panels.close(); Term.float(["nmtui-connect", modelData.ssid]); }
                            }
                        }
                        Mono { visible: Wifi.ip !== ""; text: "ip " + Wifi.ip; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                        Line { text: "open network manager"; side: Icons.chevron; onClicked: { Panels.close(); Term.float(["nmtui"]); } }
                    }

                    Section {
                        id: btSection
                        key: "bt"; icon: Icons.bluetooth; title: "bluetooth"
                        readonly property var devices: adapter ? Array.from(adapter.devices.values).filter(d => d.paired || d.connected) : []
                        summary: !(adapter?.enabled) ? "off" : devices.filter(d => d.connected).map(d => d.name).join(", ") || "on"
                        Repeater {
                            model: btSection.devices
                            Line {
                                required property var modelData
                                text: modelData.name
                                side: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "% · " : "") + "connected" : "paired"
                                active: modelData.connected
                                onClicked: modelData.connected = !modelData.connected
                            }
                        }
                        Line { text: "open bluetooth manager"; side: Icons.chevron; onClicked: { Panels.close(); Term.float(["bluetui"]); } }
                    }

                    Section {
                        key: "audio"; icon: Audio.muted ? Icons.volumeOff : Icons.volume; title: "audio"
                        summary: Audio.ready ? (Audio.muted ? "muted" : Audio.volume + "%") + " · " + (Audio.sink ? Audio.label(Audio.sink) : "") : "--"
                        Slider {
                            Layout.fillWidth: true
                            icon: Audio.muted ? Icons.volumeOff : Icons.volume
                            value: Audio.ready ? Audio.volume / 100 : 0
                            label: Audio.ready ? Audio.volume + "%" : "--"
                            onMoved: v => Audio.setVolume(v)
                        }
                        Mono { text: "output"; color: Colors.fgMuted; font.pixelSize: Style.fontSm }
                        Repeater {
                            model: Audio.sinks
                            Line {
                                required property var modelData
                                text: Audio.label(modelData)
                                active: modelData === Audio.sink
                                side: modelData === Audio.sink ? "in use" : ""
                                onClicked: Audio.setSink(modelData)
                            }
                        }
                        Mono {
                            visible: Privacy.active
                            text: "in use: " + Privacy.micApps.concat(Privacy.videoApps).join(", ")
                            color: Colors.alert
                            font.pixelSize: Style.fontSm
                        }
                    }

                    Section {
                        key: "display"; icon: Icons.brightness; title: "display"
                        summary: (Brightness.percent >= 0 ? Brightness.percent + "%" : "--") + (Sunset.on ? " · night light" : "")
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
                    }

                    Section {
                        visible: Battery.present
                        key: "battery"; icon: Battery.charging ? Icons.charging : Icons.batteryFor(Battery.percent); title: "battery"
                        summary: Battery.percent + "% · " + Battery.status
                        Mono {
                            text: (Battery.timeLeft !== "" ? (Battery.charging ? "full in " : "") + Battery.timeLeft + (Battery.charging ? "" : " left") + " · " : "")
                                + (Battery.watts > 0 ? Battery.watts.toFixed(1) + " W" : "--")
                                + (Battery.health >= 0 ? " · health " + Math.round(Battery.health) + "%" : "")
                            color: Colors.fgMuted
                        }
                        RowLayout {
                            spacing: Style.padLg
                            Mono { text: "mode"; color: Colors.fgMuted }
                            Repeater {
                                model: [{ label: "eco", p: PowerProfile.PowerSaver }, { label: "balanced", p: PowerProfile.Balanced }, { label: "performance", p: PowerProfile.Performance }]
                                MonoButton {
                                    required property var modelData
                                    readonly property bool current: Power.profile === modelData.p
                                    visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                                    text: current ? "[" + modelData.label + "]" : modelData.label
                                    color: current ? Colors.accent : Colors.fgMuted
                                    onClicked: PowerProfiles.profile = modelData.p
                                }
                            }
                        }
                    }

                    Section {
                        key: "notifs"; icon: Notifs.dnd ? Icons.bellOff : Icons.bell; title: "notifications"
                        summary: Notifs.history.length + (Notifs.dnd ? " · silent" : "")
                        RowLayout {
                            Layout.fillWidth: true
                            visible: Notifs.history.length > 0
                            Item { Layout.fillWidth: true }
                            MonoButton { text: "clear all"; color: Colors.accent; onClicked: Notifs.clearHistory() }
                        }
                        Mono { visible: Notifs.history.length === 0; text: "nothing new"; color: Colors.fgMuted }
                        Repeater {
                            model: Notifs.history.slice(0, 20)
                            ColumnLayout {
                                id: entry
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 0
                                Mono {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    color: entry.modelData.critical ? Colors.alert : Colors.fg
                                    text: entry.modelData.time + "  " + entry.modelData.app.toLowerCase() + " · " + entry.modelData.summary
                                }
                                Mono {
                                    visible: entry.modelData.body !== ""
                                    Layout.fillWidth: true
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

            Mono {
                id: hint
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.pad }
                text: "click a line to unfold · esc close"
                color: Colors.fgMuted
                font.pixelSize: Style.fontSm
            }
        }
    }
}
