pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The connected Wi-Fi network, checked every 10 seconds.
Singleton {
    id: root
    property string ssid: ""
    readonly property bool connected: ssid !== ""

    Process {
        id: poll
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: root.ssid = text.trim() }
    }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
