pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Pending official-repo updates from checkupdates (pacman-contrib), hourly.
// -1 until checked or if the check fails (shown as --).
Singleton {
    id: root
    property int count: -1

    function parse(text) {
        // checkupdates exits 0 = updates listed, 2 = none, anything else = could not check
        const lines = text.trim().split("\n");
        const code = Number((lines.pop() || "").replace("EXIT ", ""));
        root.count = code === 0 ? lines.filter(l => l).length : code === 2 ? 0 : -1;
    }

    Process {
        id: check
        command: ["sh", "-c", 'checkupdates 2>/dev/null; echo "EXIT $?"']
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { interval: 3600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: check.running = true }
}
