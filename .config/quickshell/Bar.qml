import Quickshell
import QtQuick

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 26
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.family: Style.font
                color: Colors.onSurface
            }
        }
    }
}
