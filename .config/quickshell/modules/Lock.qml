import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

Scope {
    id: root
    readonly property bool lockOnStart: true // login screen behavior
    property string password: ""
    property string status: ""
    property bool busy: false

    function tryUnlock() {
        if (busy || password.length === 0) return;
        busy = true;
        status = "[auth] checking";
        pam.start();
    }

    // Lock once per login, never on a reload (a wallpaper change reloads the shell).
    // The decision runs in onLoaded: Quickshell restores these values during the
    // reload stage, after Component.onCompleted, so checking earlier always saw
    // the default and relocked mid-reload.
    PersistentProperties {
        id: persist
        reloadableId: "lockState"
        property bool startLockDone: false

        onLoaded: {
            if (root.lockOnStart && !startLockDone) {
                startLockDone = true;
                sessionLock.locked = true;
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { sessionLock.locked = true; }
        function isLocked(): bool { return sessionLock.locked; }
    }

    PamContext {
        id: pam
        onPamMessage: {
            if (pam.responseRequired) pam.respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                root.status = "";
            } else {
                root.status = "[fail] try again";
            }
            root.password = "";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            color: Colors.bg

            Image {
                anchors.fill: parent
                source: Wall.path !== "" ? "file://" + Wall.path : ""
                fillMode: Image.PreserveAspectCrop
            }
            Rectangle { anchors.fill: parent; color: "black"; opacity: 0.6 }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.padLg

                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    text: Clock.format("HH:mm")
                    font.pixelSize: Style.fontXl * 2
                }
                Mono {
                    Layout.alignment: Qt.AlignHCenter
                    text: Clock.format("dddd dd MMMM").toLowerCase()
                    color: Colors.fgMuted
                }

                Rectangle {
                    readonly property bool failed: root.status.startsWith("[fail]")
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    implicitHeight: Style.rowHeight + Style.pad
                    color: Colors.panel
                    border { width: Style.border; color: failed ? Colors.alert : Colors.border }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Style.pad; rightMargin: Style.pad }
                        spacing: Style.pad

                        Mono { text: ">"; color: Colors.accent; font.pixelSize: Style.fontLg }
                        TextInput {
                            id: field
                            Layout.fillWidth: true
                            focus: true
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: Colors.fg
                            font.family: Style.font
                            font.pixelSize: Style.fontLg
                            onTextChanged: root.password = text
                            onAccepted: root.tryUnlock()
                            Component.onCompleted: forceActiveFocus()

                            Connections {
                                target: root
                                function onPasswordChanged() { if (root.password === "") field.text = ""; }
                            }
                        }
                    }
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
