pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which overlay is open: "", "apps", "clip", "sheet", "leader", "power" or "picker".
// One at a time: opening one closes the others.
Singleton {
    id: root
    property string open: ""

    function toggle(name) { open = (open === name) ? "" : name; }
    function close() { open = ""; }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle("apps"); }
        function clipboard(): void { root.toggle("clip"); }
    }
    IpcHandler {
        target: "keys"
        function cheatsheet(): void { root.toggle("sheet"); }
        function leader(): void { root.toggle("leader"); }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle("power"); }
    }
    IpcHandler {
        target: "picker"
        function toggle(): void { root.toggle("picker"); }
    }
}
