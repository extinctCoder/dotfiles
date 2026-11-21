import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Warns once at 15% and once at 5% while on battery; resets when plugged in.
Scope {
    id: root
    readonly property var bat: UPower.displayDevice
    readonly property int pct: Math.round((bat?.percentage ?? 1) * 100)
    readonly property bool discharging: bat?.state === UPowerDeviceState.Discharging
    property int warned: 100 // lowest level already warned about

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "battery", "-u", urgency, title, body]);
    }

    function check() {
        if (!(bat?.isLaptopBattery ?? false)) return;
        if (!discharging) { warned = 100; return; }
        if (pct <= 5 && warned > 5) {
            warned = 5;
            notify("critical", "battery " + pct + "%", "plug in now");
        } else if (pct <= 15 && warned > 15) {
            warned = 15;
            notify("normal", "battery " + pct + "%", "plug in soon");
        }
    }

    onPctChanged: check()
    onDischargingChanged: check()
    Component.onCompleted: check()
}
