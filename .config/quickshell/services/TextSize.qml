pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// One text size for the shell, GTK apps and Ghostty.
//   shell:   Style reads ~/.local/state/textscale
//   GTK:     gsettings font-name / monospace-font-name (11pt x scale)
//   Ghostty: ~/.config/ghostty/size.conf (12pt x scale), included by its config
Singleton {
    id: root
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/textscale"
    property real scale: 1
    readonly property var steps: [0.9, 1, 1.15, 1.3]

    function set(s) {
        root.scale = Math.max(0.8, Math.min(1.5, Math.round(s * 20) / 20));
        const gtk = Math.round(11 * root.scale), term = Math.round(12 * root.scale);
        apply.command = ["sh", "-c",
            'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"; '
            + 'gsettings set org.gnome.desktop.interface font-name "FiraCode Nerd Font $3"; '
            + 'gsettings set org.gnome.desktop.interface monospace-font-name "FiraCode Nerd Font $3"; '
            + 'printf "font-size = %s\\n" "$4" > "$HOME/.config/ghostty/size.conf"; '
            + 'pkill -USR2 -x ghostty; true',
            "sh", root.stateFile, String(root.scale), String(gtk), String(term)];
        apply.running = true;
    }
    function step(dir) {
        const i = root.steps.findIndex(v => v >= root.scale - 0.001);
        const next = Math.max(0, Math.min(root.steps.length - 1, (i < 0 ? root.steps.length - 1 : i) + dir));
        root.set(root.steps[next]);
    }

    Process { id: apply }

    FileView {
        path: root.stateFile
        printErrors: false
        onLoaded: {
            const s = Number(text().trim());
            if (s >= 0.8 && s <= 1.5) root.scale = s;
        }
    }
    // at login: apply the saved size everywhere (GTK and Ghostty start from defaults)
    Timer { interval: 1500; running: true; onTriggered: root.set(root.scale) }

    IpcHandler {
        target: "textsize"
        function set(s: real): void { root.set(s); }
        function step(dir: int): void { root.step(dir); }
    }
}
