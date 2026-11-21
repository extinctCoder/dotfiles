pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon. Always on (started from shell.qml).
Singleton {
    id: root
    readonly property var list: server.trackedNotifications
    readonly property bool any: server.trackedNotifications.values.length > 0

    function clear() {
        for (const n of Array.from(server.trackedNotifications.values)) n.dismiss();
    }

    // left click: run the default action, then close; right click: just close
    function activate(n, runDefault) {
        const def = Array.from(n.actions).find(a => a.identifier === "default");
        if (runDefault && def) def.invoke();
        n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        onNotification: n => n.tracked = true
    }

    IpcHandler {
        target: "notifs"
        function clear(): void { root.clear(); }
    }
}
