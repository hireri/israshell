pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.style
import qs.services
import qs.icons
import qs.settings.components

PageBase {
    id: page
    title: "Network"
    subtitle: "Wi-Fi and Bluetooth"

    onVisibleChanged: if (visible)
        NetworkService._updateAll()

    readonly property bool wifiBusy: NetworkService.wifiConnecting || NetworkService.scanning

    property bool btDeviceBusy: false

    function signalIcon(s) {
        if (s >= 80)
            return "󰤨";
        if (s >= 75)
            return "󰤥";
        if (s >= 50)
            return "󰤢";
        if (s >= 25)
            return "󰤟";
        return "󰤯";
    }

    function editConnection(ssid) {
        editProc.command = ["bash", "-c", "nm-connection-editor --edit=\"$(nmcli -g uuid,name connection show | grep " + JSON.stringify(ssid) + " | head -1 | cut -d: -f1)\""];
        editProc.running = false;
        editProc.running = true;
    }

    Process {
        id: editProc
    }

    Connections {
        target: BluetoothService
        function onConnectedDevicesChanged() {
            page.btDeviceBusy = false;
        }
        function onAllDevicesChanged() {
            page.btDeviceBusy = false;
        }
    }

    Timer {
        id: btBusyTimeout
        interval: 8000
        running: page.btDeviceBusy
        onTriggered: page.btDeviceBusy = false
    }

    Component {
        id: ethIconComp
        EthernetIcon {
            iconSize: 22
            filled: NetworkService.ethConnected
            color: NetworkService.ethConnected ? Colors.md3.on_tertiary_container : Colors.md3.outline
        }
    }
    Component {
        id: wifiIconComp
        WifiIcon {
            iconSize: 22
            strength: NetworkService.wifiConnected ? NetworkService.wifiSignal : 0
            secured: (NetworkService.activeNetwork?.security ?? "").length > 0
            color: NetworkService.wifiEnabled ? Colors.md3.on_primary_container : Colors.md3.outline
        }
    }
    Component {
        id: btIconComp
        BluetoothIcon {
            iconSize: 22
            filled: BluetoothService.bluetoothEnabled
            color: BluetoothService.bluetoothEnabled ? Colors.md3.on_secondary_container : Colors.md3.outline
        }
    }
    Component {
        id: headphonesComp
        HeadphonesIcon {
            iconSize: 22
            color: Colors.md3.on_secondary_container
        }
    }
    Component {
        id: phoneComp
        PhoneIcon {
            iconSize: 22
            color: Colors.md3.on_secondary_container
        }
    }
    Component {
        id: keyboardComp
        KeyboardIcon {
            iconSize: 22
            color: Colors.md3.on_secondary_container
        }
    }

    Component {
        id: btRowHeadphones
        HeadphonesIcon {
            iconSize: 20
            color: Colors.md3.on_surface
        }
    }
    Component {
        id: btRowPhone
        PhoneIcon {
            iconSize: 20
            color: Colors.md3.on_surface
        }
    }
    Component {
        id: btRowGeneric
        BluetoothIcon {
            iconSize: 20
            filled: true
            color: Colors.md3.on_surface
        }
    }

    function btCardIcon() {
        const ico = BluetoothService.firstConnected?.icon ?? "";
        if (ico.includes("headset") || ico.includes("headphone"))
            return headphonesComp;
        if (ico.includes("phone"))
            return phoneComp;
        if (ico.includes("keyboard"))
            return keyboardComp;
        return btIconComp;
    }

    function btRowIcon(iconStr) {
        const s = iconStr ?? "";
        if (s.includes("headset") || s.includes("headphone"))
            return btRowHeadphones;
        if (s.includes("phone"))
            return btRowPhone;
        return btRowGeneric;
    }

    NetworkCard {
        Layout.fillWidth: true
        enabled: NetworkService.ethConnected
        tint: Colors.md3.tertiary_container
        onTint: Colors.md3.on_tertiary_container
        iconComponent: ethIconComp
        title: "Ethernet"
        subtitle: NetworkService.ethConnected ? "Connected" : "Not connected"
        hasSwitch: NetworkService.ethAvailable
        switchChecked: NetworkService.ethConnected
        onSwitchToggled: NetworkService.toggleEthernet()
    }

    NetworkCard {
        id: wifiCard
        Layout.fillWidth: true
        enabled: NetworkService.wifiEnabled
        tint: Colors.md3.primary_container
        onTint: Colors.md3.on_primary_container
        iconComponent: wifiIconComp
        title: NetworkService.wifiConnected ? NetworkService.wifiSsid : "Wi-Fi"
        subtitle: NetworkService.wifiConnecting ? "Connecting…" : NetworkService.wifiConnected ? "Strength: " + NetworkService.wifiSignal + "%" : NetworkService.wifiEnabled ? "Not connected" : "Off"
        hasSwitch: true
        switchChecked: NetworkService.wifiEnabled
        onSwitchToggled: NetworkService.toggle()
    }

    Spinner {
        Layout.fillWidth: true
        running: page.wifiBusy
        color: Colors.md3.primary
    }

    SectionCard {
        Layout.fillWidth: true
        visible: NetworkService.wifiEnabled && NetworkService.sortedNetworks.length > 0

        Item {
            implicitWidth: parent?.width ?? 0
            implicitHeight: 36

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 8

                Text {
                    text: "Available networks"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 24
                    width: scanTxt.implicitWidth + 14
                    radius: 12
                    color: Colors.md3.surface_container_high
                    visible: !NetworkService.scanning

                    Text {
                        id: scanTxt
                        anchors.centerIn: parent
                        text: "Scan"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.setScanning(true)
                    }
                }

                Text {
                    text: "Scanning…"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    visible: NetworkService.scanning
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    leftMargin: 18
                    right: parent.right
                    rightMargin: 18
                }
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.5
            }
        }

        Repeater {
            id: netRepeater
            model: NetworkService.sortedNetworks

            delegate: Item {
                required property var modelData
                required property int index

                property bool rowLoading: false

                implicitWidth: parent?.width ?? 0
                implicitHeight: 52

                Connections {
                    target: NetworkService
                    function onNetworksChanged() {
                        rowLoading = false;
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 14
                    }
                    spacing: 8

                    Text {
                        text: signalIcon(modelData.strength)
                        font.pixelSize: 15
                        font.family: Config.fontMonospace
                        color: modelData.active ? Colors.md3.primary : Colors.md3.outline
                        opacity: modelData.active ? 1 : 0.7
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "󰌆"
                        font.pixelSize: 11
                        font.family: Config.fontMonospace
                        color: Colors.md3.outline
                        visible: (modelData.security ?? "").length > 0
                        opacity: 0.5
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: modelData.ssid
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: modelData.active ? Font.Medium : Font.Normal
                            color: Colors.md3.on_surface
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.active ? "Connected" : modelData.known ? "Saved · " + modelData.strength + "%" : modelData.strength + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: modelData.active ? Colors.md3.primary : Colors.md3.outline
                        }
                    }

                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter
                        opacity: rowLoading ? 0.4 : 1
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: Colors.md3.surface_container_high
                            visible: modelData.known

                            Text {
                                anchors.centerIn: parent
                                text: "󰏫"
                                font.pixelSize: 13
                                font.family: Config.fontMonospace
                                color: Colors.md3.outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !rowLoading
                                onClicked: editConnection(modelData.ssid)
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: Colors.md3.surface_container_high
                            visible: modelData.known && !modelData.active

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.pixelSize: 15
                                color: Colors.md3.outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !rowLoading
                                onClicked: {
                                    rowLoading = true;
                                    NetworkService.forgetNetwork(modelData.ssid);
                                }
                            }
                        }

                        Rectangle {
                            height: 28
                            width: connTxt.implicitWidth + 16
                            radius: 14
                            color: modelData.active ? Colors.md3.surface_container_high : Colors.md3.secondary_container

                            Text {
                                id: connTxt
                                anchors.centerIn: parent
                                text: modelData.active ? "Disconnect" : "Connect"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: modelData.active ? Colors.md3.on_surface_variant : Colors.md3.on_secondary_container
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !rowLoading
                                onClicked: {
                                    rowLoading = true;
                                    if (modelData.active)
                                        NetworkService.disconnectNetwork(modelData.ssid);
                                    else
                                        NetworkService.connectNetwork(modelData.ssid);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: index < netRepeater.count - 1
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 18
                        right: parent.right
                        rightMargin: 18
                    }
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }
        }
    }

    NetworkCard {
        id: btCard
        Layout.fillWidth: true
        enabled: BluetoothService.bluetoothEnabled
        tint: Colors.md3.secondary_container
        onTint: Colors.md3.on_secondary_container
        iconComponent: btCardIcon()
        title: BluetoothService.firstConnected?.name ?? "Bluetooth"
        subtitle: !BluetoothService.bluetoothEnabled ? "Off" : BluetoothService.connectedDevices.length > 0 ? (BluetoothService.firstConnected?.batteryAvailable ? "Connected · " + Math.round(BluetoothService.firstConnected.battery * 100) + "% battery" : "Connected") : "No devices connected"
        hasSwitch: true
        switchChecked: BluetoothService.bluetoothEnabled
        onSwitchToggled: BluetoothService.toggle()
    }

    Spinner {
        Layout.fillWidth: true
        running: page.btDeviceBusy
        color: Colors.md3.secondary
    }

    SectionCard {
        label: "Paired devices"
        Layout.fillWidth: true
        visible: BluetoothService.bluetoothEnabled && BluetoothService.allDevices.length > 0

        Repeater {
            id: btRepeater
            model: BluetoothService.allDevices

            delegate: Item {
                required property BluetoothDevice modelData
                required property int index

                implicitWidth: parent?.width ?? 0
                implicitHeight: 58

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 14
                    }
                    spacing: 12

                    Item {
                        width: 20
                        height: 20
                        Layout.alignment: Qt.AlignVCenter
                        opacity: modelData.connected ? 1 : 0.4

                        Loader {
                            anchors.centerIn: parent
                            sourceComponent: btRowIcon(modelData.icon)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: modelData.name
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: modelData.connected ? Font.Medium : Font.Normal
                            color: Colors.md3.on_surface
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.connected ? (modelData.batteryAvailable ? "Connected · " + Math.round(modelData.battery * 100) + "% battery" : "Connected") : modelData.pairing ? "Pairing…" : "Paired"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: modelData.connected ? Colors.md3.primary : Colors.md3.outline
                        }
                    }

                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: 28
                            width: btConnTxt.implicitWidth + 16
                            radius: 14
                            color: modelData.connected ? Colors.md3.surface_container_high : Colors.md3.secondary_container

                            Text {
                                id: btConnTxt
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Connect"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: modelData.connected ? Colors.md3.on_surface_variant : Colors.md3.on_secondary_container
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.btDeviceBusy = true;
                                    if (modelData.connected)
                                        BluetoothService.disconnectDevice(modelData);
                                    else
                                        BluetoothService.connectDevice(modelData);
                                }
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: Colors.md3.surface_container_high

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.pixelSize: 15
                                color: Colors.md3.outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.btDeviceBusy = true;
                                    BluetoothService.forgetDevice(modelData);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: index < btRepeater.count - 1
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 18
                        right: parent.right
                        rightMargin: 18
                    }
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }
        }
    }
}
