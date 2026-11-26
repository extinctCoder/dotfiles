import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Super+Space: one box for everything. Plain text searches apps, actions, math,
// files and Zen bookmarks/history (3+ letters), and offers a Google search last.
// A pasted link offers "play in mpv". Prefixes narrow it:
//   >  actions   /  files   @  bookmarks + history   =  calculator   ?  web search
//   yt <words>  YouTube search, plays in mpv
// Super+V opens the same box on clipboard history.
// Arrows or Tab to move, Enter to run, Esc or click outside to close.
LazyLoader {
    active: Panels.open === "apps" || Panels.open === "clip"

    PanelWindow {
        id: win
        readonly property bool clip: Panels.open === "clip"
        property string confirming: "" // title of an action waiting for a second Enter

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"

        Component.onCompleted: if (clip) Clipboard.load()

        function web(q) {
            return { kind: "web", title: "search google for \"" + q + "\"", sub: "web", glyph: Icons.web,
                run: () => Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(q)]) };
        }
        function build(text) {
            const t = text.trim();
            if (t.startsWith(">")) return Actions.search(t.slice(1).trim());
            if (t.startsWith("/")) return Files.results;
            if (t.startsWith("@")) return Places.results;
            if (t.startsWith("=")) return Calc.rows(t.slice(1), true);
            if (t.startsWith("?")) return t.length > 1 ? [web(t.slice(1).trim())] : [];
            if (/^yt\s/i.test(t)) return YouTube.results.length ? YouTube.results
                : [{ kind: "info", title: YouTube.busy ? "searching youtube..." : "no results", sub: "", glyph: Icons.youtube, run: () => {} }];
            if (/^https?:\/\/\S+$/i.test(t))
                return [{ kind: "url", title: "play in mpv", sub: t, glyph: Icons.play, run: () => YouTube.play(t) }, web(t)];
            let out = Calc.rows(t, false);
            const items = Apps.rows(t).concat(Actions.search(t).map(a => Object.assign(a, { score: Apps.score(t, a.title) + 0.5 })));
            out = out.concat(items.sort((a, b) => a.score - b.score));
            if (t.length >= 3) out = out.concat(Places.results.slice(0, 3), Files.results.slice(0, 5));
            if (t !== "") out.push(web(t));
            return out.slice(0, 60);
        }

        MouseArea { anchors.fill: parent; onClicked: Panels.close() }

        Rectangle {
            id: box
            // flush under the bar's left corner (the logo opens it)
            anchors { top: parent.top; left: parent.left; topMargin: Style.barHeight - Style.border }
            width: 620
            height: content.implicitHeight + Style.pad * 2
            color: Colors.raised
            Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: Style.border; color: Colors.border }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Style.border; color: Colors.border }

            MouseArea { anchors.fill: parent } // clicks inside stay inside

            readonly property var results: win.clip
                ? Clipboard.search(input.text).map(c => ({ kind: "clip", title: Clipboard.label(c), sub: "", glyph: Icons.clipboard, run: () => Clipboard.copy(c) }))
                : win.build(input.text)

            function activate(index) {
                const item = results[index];
                if (item === undefined || item.kind === "info") return; // status rows do nothing
                if (item.confirm && win.confirming !== item.title) { win.confirming = item.title; return; }
                Panels.close();
                item.run();
            }

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
                spacing: Style.gap

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.pad
                    Mono { text: win.clip ? "clip>" : ">"; color: Colors.accent; font.pixelSize: Style.fontLg }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        focus: true
                        color: Colors.fg
                        selectionColor: Colors.accent
                        font.family: Style.font
                        font.pixelSize: Style.fontLg
                        Component.onCompleted: forceActiveFocus()
                        onTextChanged: {
                            list.currentIndex = 0;
                            win.confirming = "";
                            const t = text.trim();
                            Files.query = win.clip ? "" : t.startsWith("/") ? t.slice(1).trim() : (/^[>=?@]/.test(t) || /^yt\s/i.test(t) ? "" : t);
                            Places.query = win.clip ? "" : t.startsWith("@") ? t.slice(1).trim() : (/^[>=?/]/.test(t) || /^yt\s/i.test(t) ? "" : t);
                            YouTube.query = !win.clip && /^yt\s/i.test(t) ? t.slice(3).trim() : "";
                        }
                        Keys.onEscapePressed: Panels.close()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onTabPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: box.activate(list.currentIndex)
                        Keys.onEnterPressed: box.activate(list.currentIndex)
                    }
                }
                Mono {
                    visible: !win.clip && input.text === ""
                    text: "> actions  / files  @ bookmarks  = math  ? web  yt youtube"
                    color: Colors.fgMuted
                    font.pixelSize: Style.fontSm
                }

                Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: Math.min(count, 9) * Style.rowHeight
                    clip: true
                    model: box.results

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem
                        width: list.width
                        height: Style.rowHeight
                        color: selected ? Colors.accent : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                            spacing: Style.pad

                            Item {
                                implicitWidth: Style.fontLg
                                implicitHeight: Style.fontLg
                                IconImage {
                                    anchors.fill: parent
                                    visible: row.modelData.icon !== undefined
                                    source: row.modelData.icon ?? ""
                                }
                                Mono {
                                    anchors.centerIn: parent
                                    visible: row.modelData.icon === undefined
                                    text: row.modelData.glyph ?? ""
                                    color: row.selected ? Colors.accentFg : Colors.accent
                                }
                            }
                            Mono {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: row.selected ? Colors.accentFg : Colors.fg
                                text: win.confirming === row.modelData.title ? row.modelData.title + "? press enter again" : row.modelData.title
                            }
                            Mono {
                                visible: row.modelData.sub !== ""
                                Layout.maximumWidth: list.width * 0.4
                                elide: Text.ElideLeft
                                color: row.selected ? Colors.accentFg : Colors.fgMuted
                                font.pixelSize: Style.fontSm
                                text: row.modelData.sub
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: box.activate(row.index)
                        }
                    }
                }

                Mono {
                    visible: list.count === 0 && input.text !== ""
                    text: "[info] no matches"
                    color: Colors.fgMuted
                }
            }
        }
    }
}
