pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Workspaces and the focused window.
Singleton {
    readonly property var workspaces: Hyprland.workspaces
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1
    readonly property string windowTitle: ToplevelManager.activeToplevel?.title ?? ""

    // Hyprland 0.55+ with a Lua config: dispatch takes a Lua dispatcher
    function focusWorkspace(id) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })"); }
}
