pragma Singleton
import Quickshell
import QtQuick

// Ghostty windows, opened through the background instance (fast).
Singleton {
    function open(args) { Quickshell.execDetached(["ghostty", "+new-window"].concat(args || [])); }
    function run(cmd) { open(["-e"].concat(cmd)); }                        // cmd: array
    function float(cmd) { open(["--title=tui.float", "-e"].concat(cmd)); } // small floating window (rules.lua)
}
