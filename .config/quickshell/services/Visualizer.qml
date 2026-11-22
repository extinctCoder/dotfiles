pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Live audio spectrum from cava (what is playing right now, through PipeWire).
// Runs only while something plays; otherwise bars are empty (flat).
Singleton {
    id: root
    property var bars: [] // 72 values, 0..1

    Process {
        running: Media.active
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/quickshell.conf"]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").filter(v => v !== "").map(v => Number(v) / 100)
        }
        onRunningChanged: if (!running) root.bars = []
    }
}
