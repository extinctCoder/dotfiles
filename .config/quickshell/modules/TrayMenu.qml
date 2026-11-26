import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// A tray app's own menu, drawn in the shell's style: hangs flush under its icon.
// Click an entry to run it; entries with a submenu unfold in place. Clicking
// outside or Esc closes it.
PopupWindow {
    id: root
    required property Item item     // the tray icon
    property var menu: null         // the app's menu (SystemTrayItem.menu)
    property string title: ""
    signal done()

    anchor.item: item
    anchor.rect.y: item.height
    anchor.rect.height: 1
    anchor.rect.width: item.width
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    grabFocus: true
    visible: true
    onVisibleChanged: if (!visible) root.done()
    implicitWidth: 260
    implicitHeight: col.implicitHeight + Style.pad * 2
    color: "transparent"

    // how one entry looks: a separator line, or a row with check state, text and arrow
    component RowView: ColumnLayout {
        id: view
        required property var entryData
        property int depth: 0
        property bool canUnfold: false
        property bool unfolded: false
        signal activated()
        Layout.fillWidth: true
        spacing: 0
        Rectangle {
            visible: view.entryData.isSeparator
            Layout.fillWidth: true
            Layout.topMargin: Style.gap
            Layout.bottomMargin: Style.gap
            height: Style.border
            color: Colors.border
        }
        Rectangle {
            visible: !view.entryData.isSeparator
            Layout.fillWidth: true
            implicitHeight: Style.rowHeight
            color: rowHover.hovered && view.entryData.enabled ? Colors.panel : "transparent"
            RowLayout {
                anchors { fill: parent; leftMargin: Style.pad + view.depth * Style.padLg; rightMargin: Style.pad }
                spacing: Style.pad
                Mono {
                    visible: view.entryData.buttonType !== 0
                    text: view.entryData.checkState === Qt.Checked ? "■" : "□"
                    color: Colors.accent
                }
                Mono {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: view.entryData.text.replace(/_/g, "") // drop mnemonic underscores
                    color: view.entryData.enabled ? Colors.fg : Colors.fgMuted
                }
                Mono { visible: view.canUnfold; text: view.unfolded ? Icons.chevronDown : Icons.chevron; color: Colors.fgMuted }
            }
            HoverHandler { id: rowHover }
            TapHandler { enabled: view.entryData.enabled; onTapped: view.activated() }
        }
    }

    // an entry inside an unfolded submenu (tray menus rarely nest deeper)
    component SubEntry: RowView {
        required property var modelData
        entryData: modelData
        depth: 1
        onActivated: { modelData.triggered(); root.done(); }
    }

    // a top-level entry; one with a submenu unfolds it in place
    component TopEntry: ColumnLayout {
        id: top
        required property var modelData
        property bool unfolded: false
        Layout.fillWidth: true
        spacing: 0
        RowView {
            entryData: top.modelData
            canUnfold: top.modelData.hasChildren
            unfolded: top.unfolded
            onActivated: {
                if (top.modelData.hasChildren) { top.unfolded = !top.unfolded; return; }
                top.modelData.triggered();
                root.done();
            }
        }
        QsMenuOpener { id: sub; menu: top.unfolded ? top.modelData : null }
        Repeater { model: top.unfolded ? sub.children : []; SubEntry {} }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.raised
        border { width: Style.border; color: Colors.border }
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: Style.border; color: Colors.raised }
        Item { focus: true; Keys.onEscapePressed: root.done() }
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.pad }
            spacing: 0
            Mono { visible: root.title !== ""; text: root.title.toLowerCase(); color: Colors.fgMuted; font.pixelSize: Style.fontSm; Layout.bottomMargin: Style.gap; Layout.leftMargin: Style.pad }
            QsMenuOpener { id: menuOpener; menu: root.menu }
            Repeater { model: menuOpener.children; TopEntry {} }
        }
    }
}
