pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Battery state, plus warnings at 15% and 5% while on battery (reset when plugged in).
Singleton {
    id: root
    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property int percent: Math.round((device?.percentage ?? 1) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool discharging: device?.state === UPowerDeviceState.Discharging
    readonly property bool low: percent <= 15 && !charging
    readonly property real watts: Math.abs(device?.changeRate ?? 0)
    readonly property real health: (device?.healthSupported ?? false) ? device.healthPercentage : -1
    readonly property string status: charging ? "charging" : discharging ? "on battery"
        : device?.state === UPowerDeviceState.FullyCharged ? "full" : "plugged in"
    readonly property string timeLeft: duration(charging ? device?.timeToFull : device?.timeToEmpty)

    function duration(s) {
        if (!s || s <= 0) return "--";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h ? h + "h " : "") + m + "m";
    }

    property int warned: 100 // lowest level already warned about

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "battery", "-u", urgency, title, body]);
    }

    function check() {
        if (!present) return;
        if (!discharging) { warned = 100; return; }
        if (percent <= 5 && warned > 5) {
            warned = 5;
            notify("critical", "battery " + percent + "%", "plug in now");
        } else if (percent <= 15 && warned > 15) {
            warned = 15;
            notify("normal", "battery " + percent + "%", "plug in soon");
        }
    }

    onPercentChanged: check()
    onDischargingChanged: check()
    Component.onCompleted: check()
}
