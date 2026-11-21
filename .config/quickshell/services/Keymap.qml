pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Keybinds and the leader menu, read from ~/.config/hypr/keymap.lua with plain `lua`,
// so the cheatsheet always matches the real binds.
Singleton {
    id: root
    property var binds: [] // { key, desc, group }
    property var leader: [] // { key, desc, cmd }

    function reload() { loader.running = true; }
    Component.onCompleted: reload()

    Process {
        id: loader
        command: ["lua", "-e",
            "package.path = os.getenv('HOME') .. '/.config/hypr/?.lua;' .. package.path " +
            "local k = require('config.keymap') " +
            "for _, b in ipairs(k.binds) do print('B\\t' .. b[1] .. '\\t' .. b[3] .. '\\t' .. b[4]) end " +
            "for _, l in ipairs(k.leader) do print('L\\t' .. l[1] .. '\\t' .. l[3] .. '\\t' .. l[2]) end"]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = [];
                const l = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f[0] === "B") b.push({ key: f[1], desc: f[2], group: f[3] });
                    if (f[0] === "L") l.push({ key: f[1], desc: f[2], cmd: f[3] });
                }
                root.binds = b;
                root.leader = l;
            }
        }
    }
}
