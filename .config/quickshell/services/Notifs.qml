pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon. Always on (started from shell.qml).
// Popups for live notifications, a history of everything, do-not-disturb
// (no popups, still recorded) and an unread count for the bell.
Singleton {
    id: root
    readonly property var list: server.trackedNotifications
    readonly property bool any: server.trackedNotifications.values.length > 0
    property alias dnd: persist.dnd
    property alias history: persist.history // newest first: { app, summary, body, time, critical }
    property alias unread: persist.unread

    signal notified(string text, bool critical) // the island shows a preview

    function clear() {
        for (const n of Array.from(server.trackedNotifications.values)) n.dismiss();
    }
    function clearHistory() { root.history = []; root.unread = 0; }
    function markRead() { root.unread = 0; }
    function plain(s) {
        return (s || "").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&");
    }

    // left click: run the default action, then close; right click: just close
    function activate(n, runDefault) {
        const def = Array.from(n.actions).find(a => a.identifier === "default");
        if (runDefault && def) def.invoke();
        n.dismiss();
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifsState"
        property bool dnd: false
        property var history: []
        property int unread: 0
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        onNotification: n => {
            const critical = n.urgency === NotificationUrgency.Critical;
            root.history = [{
                app: n.appName || "app", summary: root.plain(n.summary), body: root.plain(n.body),
                time: Qt.formatDateTime(new Date(), "HH:mm"), critical: critical
            }].concat(root.history).slice(0, 50);
            root.unread += 1;
            if (root.dnd && !critical) return; // recorded, but no popup
            n.tracked = true;
            root.notified((n.appName || "app") + ": " + n.summary, critical);
        }
    }

    IpcHandler {
        target: "notifs"
        function clear(): void { root.clear(); }
        function dnd(): void { root.dnd = !root.dnd; }
    }
}
