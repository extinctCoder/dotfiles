pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi from NetworkManager (nmcli), checked every 10 s:
// radio on/off, the connected network, its signal, nearby networks and the IP.
Singleton {
    id: root
    property bool radio: true
    property string ssid: ""
    property int signal: -1
    property string ip: ""
    property var networks: [] // [{ ssid, signal, active }], strongest first
    readonly property bool connected: ssid !== ""

    function refresh() { poll.running = true; }
    function setRadio(on) {
        toggle.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        toggle.running = true;
    }

    Process {
        id: poll
        command: ["sh", "-c",
            'echo "RADIO $(nmcli radio wifi)"; '
            + 'nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | sed "s/^/NET /"; '
            + 'echo "IP $(ip -4 -o addr show scope global | head -n 1 | tr -s " " | cut -d " " -f 4)"']
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = [];
                let ssid = "", signal = -1;
                for (const line of text.split("\n")) {
                    if (line.startsWith("RADIO ")) root.radio = line.slice(6).trim() === "enabled";
                    else if (line.startsWith("IP ")) root.ip = line.slice(3).trim();
                    else if (line.startsWith("NET ")) {
                        // ACTIVE:SIGNAL:SSID (SSID may contain escaped colons)
                        const f = line.slice(4).split(":");
                        const name = f.slice(2).join(":").replace(/\\:/g, ":");
                        if (!name) continue;
                        const n = { ssid: name, signal: Number(f[1]), active: f[0] === "yes" };
                        if (n.active) { ssid = n.ssid; signal = n.signal; }
                        if (!nets.some(x => x.ssid === n.ssid)) nets.push(n);
                    }
                }
                root.ssid = ssid;
                root.signal = signal;
                root.networks = nets.sort((a, b) => b.signal - a.signal);
            }
        }
    }
    Process { id: toggle; onExited: root.refresh() }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
