import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "clock"
    popupWidth: 340
    property int monthOffset: 0
    onVisibleChanged: if (visible) monthOffset = 0

    readonly property date shownMonth: { const d = new Date(Clock.now); d.setDate(1); d.setMonth(d.getMonth() + monthOffset); return d; }
    readonly property var days: {
        const first = new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1);
        const lead = (first.getDay() + 6) % 7; // weeks start on monday
        const count = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + 1, 0).getDate();
        const today = new Date(Clock.now);
        const out = [];
        for (let i = 0; i < lead; i++) out.push({ n: "", today: false });
        for (let d = 1; d <= count; d++)
            out.push({ n: String(d), today: monthOffset === 0 && d === today.getDate() });
        return out;
    }

    // calendar
    RowLayout {
        Layout.fillWidth: true
        MonoButton { text: "<"; color: Colors.accent; onClicked: root.monthOffset -= 1 }
        Mono { text: Qt.formatDate(root.shownMonth, "MMMM yyyy").toLowerCase(); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        MonoButton { text: ">"; color: Colors.accent; onClicked: root.monthOffset += 1 }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 0
        rowSpacing: 2
        Repeater {
            model: ["mo", "tu", "we", "th", "fr", "sa", "su"]
            Mono { required property string modelData; text: modelData; color: Colors.fgMuted; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        }
        Repeater {
            model: root.days
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Style.rowHeight
                color: modelData.today ? Colors.accent : "transparent"
                Mono { anchors.centerIn: parent; text: modelData.n; color: parent.modelData.today ? Colors.accentFg : Colors.fg }
            }
        }
    }

    // weather
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "weather · " + Weather.place; color: Colors.fgMuted }
    RowLayout {
        Layout.fillWidth: true
        Mono { text: Weather.deg(Weather.temp); font.pixelSize: Style.fontXl; color: Colors.accent }
        Mono { text: Weather.ok ? Weather.condition + " · feels " + Weather.deg(Weather.feels) : "--"; color: Colors.fgMuted; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
    }
    // next hours: bar heights scale between the coolest and warmest real values
    Row {
        id: hours
        Layout.fillWidth: true
        visible: Weather.hours.length > 0
        spacing: 3
        readonly property var temps: Weather.hours.map(h => h.temp)
        readonly property real lo: Math.min(...temps)
        readonly property real hi: Math.max(...temps)
        Repeater {
            model: Weather.hours
            Column {
                required property var modelData
                required property int index
                width: (hours.width - hours.spacing * (Weather.hours.length - 1)) / Weather.hours.length
                spacing: 2
                Item {
                    width: parent.width; height: 34
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 6 + 28 * (hours.hi > hours.lo ? (modelData.temp - hours.lo) / (hours.hi - hours.lo) : 0.5)
                        color: index === 0 ? Colors.accent : Colors.border
                    }
                }
                Mono { text: modelData.hour; font.pixelSize: Style.fontSm; color: Colors.fgMuted; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
    Mono { visible: Weather.ok; text: "sunrise " + Weather.sunrise + " · sunset " + Weather.sunset; color: Colors.fgMuted }

    // world clock
    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "world"; color: Colors.fgMuted }
    Repeater {
        model: WorldClock.times
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Mono { text: modelData.name; Layout.fillWidth: true }
            Mono { text: modelData.diff; color: Colors.fgMuted }
            Mono { text: modelData.time; color: Colors.accent }
        }
    }
    Mono { visible: WorldClock.times.length === 0; text: "--"; color: Colors.fgMuted }
}
