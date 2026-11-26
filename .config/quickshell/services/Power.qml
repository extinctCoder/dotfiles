pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Power profile (eco / bal / perf) and session actions.
Singleton {
    id: root
    readonly property int profile: PowerProfiles.profile
    readonly property string profileName:
        profile === PowerProfile.PowerSaver ? "eco" : profile === PowerProfile.Performance ? "perf" : "bal"

    function cycleProfile() {
        if (profile === PowerProfile.PowerSaver) PowerProfiles.profile = PowerProfile.Balanced;
        else if (profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = PowerProfile.Performance;
        else PowerProfiles.profile = PowerProfile.PowerSaver;
    }

    // confirm: ask [y/n] first in the power menu
    readonly property var actions: [
        { key: "l", label: "lock",      confirm: false, cmd: ["qs", "ipc", "call", "lock", "lock"] },
        { key: "o", label: "log out",   confirm: false, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { key: "s", label: "sleep",     confirm: false, cmd: ["systemctl", "suspend"] },
        { key: "r", label: "reboot",    confirm: true,  cmd: ["systemctl", "reboot"] },
        { key: "u", label: "reboot to firmware (uefi)", confirm: true, cmd: ["systemctl", "reboot", "--firmware-setup"] },
        { key: "x", label: "shut down", confirm: true,  cmd: ["systemctl", "poweroff"] }
    ]

    function run(action) { if (action) Quickshell.execDetached(action.cmd); }
}
