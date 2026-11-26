import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.theme
import qs.services

// An app's icon: from YAMIS in exactly one color (the accent, live: a shader
// keeps the icon's shape and paints it), or the regular icon when YAMIS
// doesn't have it (or isn't installed).
Item {
    id: root
    property string name: ""          // app id, desktop entry id or icon name
    property string fallback: ""      // an icon source to use when YAMIS has nothing
    property int size: Style.fontMd
    property color color: Colors.accent
    readonly property var entry: name ? DesktopEntries.heuristicLookup(name) : null
    readonly property string mono: AppIcons.find([entry?.icon, name, entry?.id])
    implicitWidth: size
    implicitHeight: size

    Image {
        id: src
        anchors.fill: parent
        visible: false
        source: root.mono
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        cache: false // the file is rewritten on wallpaper changes
    }
    ShaderEffect {
        anchors.fill: parent
        visible: root.mono !== ""
        property var source: src
        property vector4d tint: Qt.vector4d(root.color.r, root.color.g, root.color.b, 1)
        fragmentShader: "../shaders/tint.frag.qsb"
    }
    IconImage {
        anchors.fill: parent
        visible: root.mono === ""
        source: root.fallback !== "" ? root.fallback
            : root.name !== "" ? Quickshell.iconPath(root.entry?.icon ?? root.name.toLowerCase(), "application-x-executable") : ""
    }
}
