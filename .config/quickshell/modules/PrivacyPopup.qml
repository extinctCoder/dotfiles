import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "privacy"
    popupWidth: 260

    Mono { text: "in use"; color: Colors.fgMuted }
    Repeater {
        model: Privacy.micApps
        Mono { required property string modelData; text: Icons.mic + "  " + modelData; color: Colors.alert }
    }
    Repeater {
        model: Privacy.videoApps
        Mono { required property string modelData; text: Icons.video + "  " + modelData; color: Colors.alert }
    }
}
