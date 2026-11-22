import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Popup {
    id: root
    name: "net"
    onVisibleChanged: if (visible) Wifi.refresh()

    Mono { text: "network"; color: Colors.fgMuted }
    RowLayout {
        Layout.fillWidth: true
        Mono { text: Wifi.connected ? Wifi.ssid : (Wifi.radio ? "not connected" : "wi-fi off"); font.pixelSize: Style.fontLg; Layout.fillWidth: true; elide: Text.ElideRight }
        Mono { text: Wifi.signal >= 0 ? Wifi.signal + "%" : "--"; color: Colors.accent }
    }
    Mono { text: "ip " + (Wifi.ip || "--"); color: Colors.fgMuted }
    Mono { text: Icons.down + " " + Sys.rate(Sys.rxRate) + "/s    " + Icons.up + " " + Sys.rate(Sys.txRate) + "/s"; color: Colors.accent }

    Rectangle { Layout.fillWidth: true; height: Style.border; color: Colors.border }
    Mono { text: "nearby"; color: Colors.fgMuted }
    Repeater {
        model: Wifi.networks.slice(0, 6)
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Mono { text: modelData.ssid; Layout.fillWidth: true; elide: Text.ElideRight; color: modelData.active ? Colors.accent : Colors.fg }
            Mono { text: modelData.signal + "%"; color: Colors.fgMuted }
        }
    }
    Mono { visible: Wifi.networks.length === 0; text: "--"; color: Colors.fgMuted }
    MonoButton {
        text: "manage networks >"
        color: Colors.accent
        onClicked: { Panels.close(); Term.float(["nmtui"]); }
    }
}
