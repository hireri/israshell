import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style
import qs.icons

Row {
    id: root

    spacing: 12

    property bool capsLockOn: false

    readonly property int notifCount: {
        let c = 0;
        const groups = NotificationService.groups;
        for (const k in groups)
            c += groups[k].messages.length;
        return c;
    }

    readonly property var activeNet: NetworkService.activeNetwork
    readonly property bool netSecured: {
        const sec = root.activeNet?.security ?? "";
        return sec !== "" && sec !== "--";
    }

    Process {
        id: capsProc
        command: [Quickshell.shellDir + "/scripts/check-capslock.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.capsLockOn = this.text.trim().length > 0
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: capsProc.running = true
    }

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        iconSize: 16
        color: Colors.md3.on_surface_variant
        mode: NetworkService.ethConnected ? "ethernet" : (NetworkService.wifiConnected ? "wifi" : "disconnected")
        strength: NetworkService.wifiSignal
        secured: root.netSecured
    }

    BluetoothIcon {
        anchors.verticalCenter: parent.verticalCenter
        iconSize: 16
        color: Colors.md3.on_surface_variant
        enabled: BluetoothService.enabled
        connected: BluetoothService.connectedCount > 0
        discovering: BluetoothService.discovering
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: BatteryService.hasBattery
        spacing: 6

        BatteryIcon {
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryService.percentage + "%"
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: NotificationService.dnd || root.notifCount > 0
        spacing: 4

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: NotificationService.dnd ? "dnd" : "notifications"
            filled: root.notifCount > 0
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.notifCount > 0
            text: root.notifCount
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.capsLockOn
        spacing: 4

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "shift-lock"
            filled: true
            iconSize: 16
            color: Colors.md3.tertiary
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Localization.t("lockSurface.caps_lock")
            color: Colors.md3.tertiary
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}
