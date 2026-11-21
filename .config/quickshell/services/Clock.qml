pragma Singleton
import Quickshell
import QtQuick

// The time, updated every minute.
Singleton {
    readonly property date now: clock.date

    function format(fmt) { return Qt.formatDateTime(clock.date, fmt); }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
