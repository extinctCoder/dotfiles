import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "mem"
    property var top: []

    Mono { text: "memory"; color: Colors.fgMuted }
    RowLayout {
        Layout.fillWidth: true
        Mono { text: Sys.pct(Sys.memPercent); font.pixelSize: Style.fontXl; color: Colors.accent; Layout.fillWidth: true }
        Mono { text: Sys.gib(Sys.memUsed) + " / " + Sys.gib(Sys.memTotal) }
    }
    Rectangle {
        Layout.fillWidth: true; height: 4; color: Colors.border
        Rectangle { width: parent.width * Math.max(0, Sys.memPercent) / 100; height: parent.height; color: Colors.accent }
    }
    Mono { text: "swap " + Sys.gib(Sys.swapUsed) + " / " + Sys.gib(Sys.swapTotal); color: Colors.fgMuted }
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "largest"; color: Colors.fgMuted }
    Repeater {
        model: root.top
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Mono { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
            Mono { text: modelData.value; color: Colors.accent }
        }
    }

    Process {
        id: ps
        // resident memory in KiB per process
        command: ["sh", "-c", "ps -eo comm,rss --sort=-rss --no-headers | head -n 5"]
        stdout: StdioCollector {
            onStreamFinished: root.top = text.trim().split("\n").filter(l => l).map(l => {
                const f = l.trim().split(/\s+/); const kib = Number(f.pop());
                return { name: f.join(" "), value: kib >= 1048576 ? (kib / 1048576).toFixed(1) + "G" : Math.round(kib / 1024) + "M" };
            })
        }
    }
    Timer { interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: ps.running = true }
}
