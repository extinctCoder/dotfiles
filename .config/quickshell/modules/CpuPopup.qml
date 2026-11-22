import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "cpu"
    property var top: []

    Mono { text: "cpu"; color: Colors.fgMuted }
    RowLayout {
        Layout.fillWidth: true
        Mono { text: Sys.pct(Sys.cpu); font.pixelSize: Style.fontXl; color: Colors.accent; Layout.fillWidth: true }
        Mono { text: Icons.temp + " " + (Sys.temp >= 0 ? Math.round(Sys.temp) + "°" : "--"); color: Sys.temp >= 85 ? Colors.alert : Colors.fg }
    }
    Mono { text: "cores"; color: Colors.fgMuted }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.padLg
        rowSpacing: Style.gap
        Repeater {
            model: Sys.cores
            RowLayout {
                required property real modelData
                required property int index
                Layout.fillWidth: true
                Mono { text: String(index).padStart(2, " "); color: Colors.fgMuted }
                Rectangle {
                    Layout.fillWidth: true; height: 4; color: Colors.border
                    Rectangle { width: parent.width * modelData / 100; height: parent.height; color: Colors.accent }
                }
            }
        }
    }
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "busiest now"; color: Colors.fgMuted }
    Repeater {
        model: root.top
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Mono { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
            Mono { text: modelData.value + "%"; color: Colors.accent }
        }
    }

    Process {
        id: ps
        // top's 2nd sample = usage right now (its 1st, like ps, is the average since start)
        command: ["sh", "-c", "top -b -n 2 -d 0.5 -o %CPU -w 512 | awk '/^ *PID/ {n++; next} n == 2 && $12 != \"top\" {print $12, $9}' | head -n 5"]
        stdout: StdioCollector {
            onStreamFinished: root.top = text.trim().split("\n").filter(l => l).map(l => {
                const f = l.trim().split(/\s+/); return { value: f.pop(), name: f.join(" ") };
            })
        }
    }
    Timer { interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: ps.running = true }
}
