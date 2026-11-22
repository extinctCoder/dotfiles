pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which overlay is open: "", "apps", "clip", "sheet", "leader", "power", "picker", "quick", "overview",
// or a bar popup: "net", "cpu", "mem", "vol", "bat", "clock", "privacy".
// One at a time: opening one closes the others.
Singleton {
    id: root
    property string open: ""

    function toggle(name) { open = (open === name) ? "" : name; }
    function close() { open = ""; }

    // Show the keybind cheatsheet once per login (false = never).
    // PersistentProperties survives shell reloads (every wallpaper change), and
    // onLoaded runs after its value is restored, so this fires only on a fresh start.
    readonly property bool cheatsheetOnLogin: true

    PersistentProperties {
        id: persist
        reloadableId: "panelsState"
        property bool welcomed: false

        onLoaded: {
            if (root.cheatsheetOnLogin && !welcomed) {
                welcomed = true;
                welcome.start();
            }
        }
    }

    Timer {
        id: welcome
        interval: 1500 // let the wallpaper and bar draw first
        onTriggered: if (root.open === "") root.open = "sheet"
    }

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
        target: "overview"
        function toggle(): void { root.toggle("overview"); }
    }
    IpcHandler {
        target: "quick"
        function toggle(): void { root.toggle("quick"); }
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
