import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool open: false
    property string mode: "apps" // "apps" or "clip"
    property var clips: []

    function show(m) {
        mode = m;
        if (m === "clip") clipList.running = true;
        open = true;
    }

    // subsequence match: "gh" matches "Ghostty"
    function fuzzy(query, str) {
        query = query.toLowerCase();
        str = str.toLowerCase();
        let i = 0;
        for (const ch of str) if (ch === query[i]) i++;
        return i >= query.length;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { if (root.open) root.open = false; else root.show("apps"); }
        function clipboard(): void { root.show("clip"); }
    }

    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.clips = text.split("\n").filter(l => l.length > 0)
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-launcher"

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Rectangle {
                id: box
                anchors.centerIn: parent
                width: 560
                height: content.implicitHeight + Style.pad * 2
                color: Colors.panel
                border { width: Style.border; color: Colors.border }

                MouseArea { anchors.fill: parent } // clicks inside stay inside

                readonly property var results: {
                    const q = input.text;
                    if (root.mode === "apps")
                        return Array.from(DesktopEntries.applications.values)
                            .filter(a => !a.noDisplay && root.fuzzy(q, a.name))
                            .sort((a, b) => a.name.localeCompare(b.name))
                            .slice(0, 50);
                    return root.clips.filter(c => root.fuzzy(q, c)).slice(0, 50);
                }

                function activate(index) {
                    const item = results[index];
                    if (item === undefined) return;
                    if (root.mode === "apps") {
                        // execute() ignores Terminal=true, so run terminal apps inside Ghostty
                        if (item.runInTerminal) Quickshell.execDetached(["ghostty", "-e"].concat(Array.from(item.command)));
                        else item.execute();
                    } else Quickshell.execDetached(["sh", "-c",
                        'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item]);
                    root.open = false;
                }

                ColumnLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                    spacing: Style.gap

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.pad

                        Mono {
                            text: root.mode === "apps" ? ">" : "clip>"
                            color: Colors.accent
                            font.pixelSize: Style.fontLg
                        }
                        TextInput {
                            id: input
                            Layout.fillWidth: true
                            focus: true
                            color: Colors.fg
                            selectionColor: Colors.accent
                            font.family: Style.font
                            font.pixelSize: Style.fontLg
                            Component.onCompleted: forceActiveFocus()
                            onTextChanged: list.currentIndex = 0
                            Keys.onEscapePressed: root.open = false
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                            Keys.onReturnPressed: box.activate(list.currentIndex)
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        implicitHeight: Math.min(count, 8) * Style.rowHeight
                        clip: true
                        model: box.results

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool selected: ListView.isCurrentItem
                            width: list.width
                            height: Style.rowHeight
                            color: selected ? Colors.accent : "transparent"

                            Mono {
                                anchors {
                                    left: parent.left; right: parent.right
                                    leftMargin: Style.pad; verticalCenter: parent.verticalCenter
                                }
                                elide: Text.ElideRight
                                color: parent.selected ? Colors.accentFg : Colors.fg
                                text: root.mode === "apps"
                                    ? modelData.name
                                    : modelData.split("\t").slice(1).join(" ")
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = index
                                onClicked: box.activate(index)
                            }
                        }
                    }

                    Mono {
                        visible: list.count === 0
                        text: "[info] no matches"
                        color: Colors.fgMuted
                    }
                }
            }
        }
    }
}
