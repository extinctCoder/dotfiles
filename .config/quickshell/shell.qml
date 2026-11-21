import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {
    // keeps the speaker's volume live for Bar and Osd
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Wallpaper {}
    Bar {}
    Launcher {}
    Notifications {}
    Osd {}
    MusicCard {}
    Battery {}
    Cheatsheet {}
    PowerMenu {}
    Lock {}
}
