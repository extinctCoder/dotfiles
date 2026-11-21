import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import QtQuick
import QtQuick.Layouts
import qs.theme

// Login screen, run by greetd. greeter-sync copies this file, your theme and your
// current wallpaper to /var/lib/qs-greeter, which the greeter user can read.
// Same look as the lock screen. Enter logs in, Tab switches session,
// Up/Down move between the user and password fields.
ShellRoot {
    id: root
    readonly property string dir: "/var/lib/qs-greeter"
    property string user: ""
    property string password: ""
    property string status: ""
    property bool busy: false
    property var sessions: [] // { name, exec, desktop }, read from /usr/share/wayland-sessions
    property int sessionIndex: 0
    readonly property var session: sessions[sessionIndex] ?? null

    component Mono: Text {
        color: Colors.fg
        font.family: Style.font
        font.pixelSize: Style.fontMd
        verticalAlignment: Text.AlignVCenter
    }

    function login() {
        if (busy || user === "" || password === "" || !session) return;
        busy = true;
        status = "[auth] checking";
        Greetd.createSession(user);
    }

    function cycleSession() {
        if (sessions.length > 0) sessionIndex = (sessionIndex + 1) % sessions.length;
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password);
            else if (error) root.status = "[warn] " + message;
        }
        function onAuthFailure(message) {
            root.busy = false;
            root.password = "";
            root.status = "[fail] " + (message || "try again");
        }
        function onReadyToLaunch() {
            const d = root.session.desktop;
            root.status = "[ok] starting " + root.session.name;
            Greetd.launch(["sh", "-c", root.session.exec],
                ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=" + d, "XDG_SESSION_DESKTOP=" + d]);
        }
        function onError(error) {
            root.busy = false;
            root.password = "";
            root.status = "[fail] " + error;
            Greetd.cancelSession();
        }
    }

    // last user who synced the greeter
    FileView {
        path: root.dir + "/user"
        printErrors: false
        onLoaded: root.user = text().trim()
    }

    // installed Wayland sessions; Hyprland first, uwsm variants skipped
    Process {
        running: true
        command: ["sh", "-c",
            'for f in /usr/share/wayland-sessions/*.desktop; do '
            + 'n=$(grep -m1 "^Name=" "$f" | cut -d= -f2-); '
            + 'e=$(grep -m1 "^Exec=" "$f" | cut -d= -f2-); '
            + 'd=$(grep -m1 "^DesktopNames=" "$f" | cut -d= -f2- | cut -d";" -f1); '
            + 'printf "%s\\t%s\\t%s\\n" "$n" "$e" "${d:-$n}"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                root.sessions = text.split("\n")
                    .filter(l => l.length > 0)
                    .map(l => { const f = l.split("\t"); return { name: f[0], exec: f[1], desktop: f[2] }; })
                    .filter(s => !s.exec.includes("uwsm"))
                    .sort((a, b) => (a.name === "Hyprland" ? 0 : 1) - (b.name === "Hyprland" ? 0 : 1));
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Colors.bg

            Image {
                anchors.fill: parent
                source: "file://" + root.dir + "/wallpaper"
                fillMode: Image.PreserveAspectCrop
                cache: false
            }
            Rectangle { anchors.fill: parent; color: "black"; opacity: 0.6 }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.padLg

                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Style.fontXl * 2
                }
                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd dd MMMM").toLowerCase()
                    color: Colors.fgMuted
                }

                // user
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    implicitHeight: Style.rowHeight + Style.pad
                    color: Colors.panel
                    border { width: Style.border; color: userField.activeFocus ? Colors.accent : Colors.border }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                        spacing: Style.pad
                        Mono { text: "user"; color: Colors.fgMuted }
                        TextInput {
                            id: userField
                            Layout.fillWidth: true
                            text: root.user
                            color: Colors.fg
                            font.family: Style.font
                            font.pixelSize: Style.fontLg
                            onTextEdited: root.user = text
                            onAccepted: passField.forceActiveFocus()
                            Keys.onDownPressed: passField.forceActiveFocus()
                            Keys.onTabPressed: root.cycleSession()
                        }
                    }
                }

                // password
                Rectangle {
                    readonly property bool failed: root.status.startsWith("[fail]")
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    implicitHeight: Style.rowHeight + Style.pad
                    color: Colors.panel
                    border { width: Style.border; color: failed ? Colors.alert : passField.activeFocus ? Colors.accent : Colors.border }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                        spacing: Style.pad
                        Mono { text: ">"; color: Colors.accent; font.pixelSize: Style.fontLg }
                        TextInput {
                            id: passField
                            Layout.fillWidth: true
                            focus: true
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: Colors.fg
                            font.family: Style.font
                            font.pixelSize: Style.fontLg
                            Component.onCompleted: forceActiveFocus()
                            onTextEdited: root.password = text
                            onAccepted: root.login()
                            Keys.onUpPressed: userField.forceActiveFocus()
                            Keys.onTabPressed: root.cycleSession()

                            Connections {
                                target: root
                                function onPasswordChanged() { if (root.password === "") passField.text = ""; }
                            }
                        }
                    }
                }

                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    color: Colors.fgMuted
                    text: "session  [" + (root.session ? root.session.name : "--") + "]  tab to switch"
                }

                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.status
                    color: root.status.startsWith("[fail]") ? Colors.alert : Colors.fgMuted
                }
            }
        }
    }
}
