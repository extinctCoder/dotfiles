import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "bat"

    Mono { text: "battery"; color: Colors.fgMuted }
    RowLayout {
        Layout.fillWidth: true
        Mono { text: Battery.present ? Battery.percent + "%" : "--"; font.pixelSize: Style.fontXl; color: Battery.low ? Colors.alert : Colors.accent; Layout.fillWidth: true }
        Mono { text: Battery.status }
    }
    Mono { text: (Battery.charging ? "full in " : "left ") + Battery.timeLeft; color: Colors.fgMuted }
    Mono { text: "power " + (Battery.watts > 0 ? Battery.watts.toFixed(1) + " W" : "--"); color: Colors.fgMuted }
    Mono { text: "health " + (Battery.health >= 0 ? Math.round(Battery.health) + "%" : "--"); color: Colors.fgMuted }
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "power mode"; color: Colors.fgMuted }
    RowLayout {
        spacing: Style.padLg
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
}
