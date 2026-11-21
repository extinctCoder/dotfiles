import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property string ssid: ""

    function tui(cmd) {
        Quickshell.execDetached(["ghostty", "+new-window", "--title=tui.float", "-e", cmd]);
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Process {
        id: wifi
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: root.ssid = text.trim() }
    }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: wifi.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Style.barHeight
            color: Colors.panel
            WlrLayershell.namespace: "quickshell-bar"

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Style.border
                color: Colors.border
            }

            // left: workspaces
            RowLayout {
                anchors { left: parent.left; leftMargin: Style.pad; verticalCenter: parent.verticalCenter }
                spacing: Style.gap

                Repeater {
                    model: Hyprland.workspaces

                    MonoButton {
                        required property var modelData
                        readonly property bool current: Hyprland.focusedWorkspace?.id === modelData.id
                        visible: modelData.id > 0
                        text: current ? "[" + modelData.id + "]" : " " + modelData.id + " "
                        color: current ? Colors.accent : Colors.fgMuted
                        font.bold: current
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                    }
                }
            }

            // center: focused window title
            Mono {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width * 0.4)
                elide: Text.ElideRight
                color: Colors.fgMuted
                text: ToplevelManager.activeToplevel?.title ?? ""
            }

            // right: status line
            RowLayout {
                anchors { right: parent.right; rightMargin: Style.pad; verticalCenter: parent.verticalCenter }
                spacing: Style.pad

                MonoButton {
                    text: root.ssid !== "" ? "wifi " + root.ssid : "wifi off"
                    color: root.ssid !== "" ? Colors.fg : Colors.alert
                    onClicked: root.tui("nmtui")
                }
                Mono { text: "·"; color: Colors.border }

                MonoButton {
                    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
                    text: !audio ? "vol --" : audio.muted ? "vol muted" : "vol " + Math.round(audio.volume * 100) + "%"
                    onClicked: root.tui("wiremix")
                }
                Mono { text: "·"; color: Colors.border }

                MonoButton {
                    readonly property int p: PowerProfiles.profile
                    text: p === PowerProfile.PowerSaver ? "eco" : p === PowerProfile.Performance ? "perf" : "bal"
                    onClicked: {
                        if (p === PowerProfile.PowerSaver) PowerProfiles.profile = PowerProfile.Balanced;
                        else if (p === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = PowerProfile.Performance;
                        else PowerProfiles.profile = PowerProfile.PowerSaver;
                    }
                }
                Mono { text: "·"; color: Colors.border }

                Mono {
                    readonly property var bat: UPower.displayDevice
                    readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
                    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
                    visible: bat?.isLaptopBattery ?? false
                    text: "bat " + pct + "%" + (charging ? "+" : "")
                    color: pct <= 15 && !charging ? Colors.alert : Colors.fg
                }
                Mono { text: "·"; color: Colors.border }

                Mono { text: Qt.formatDateTime(clock.date, "ddd dd  HH:mm") }
            }
        }
    }
}
