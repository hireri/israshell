pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Qt.labs.platform as Labs
import qs.style
import qs.services
import qs.icons
import qs.windows.components
import qs.components
import "../services/ShellQuote.js" as ShellQuote

PageBase {
    pageId: "network"
    id: page
    title: Localization.t("settingsWindow.connectivity")
    subtitle: Localization.t("networkPage.wi_fi_and_bluetooth")

    onActiveChanged: {
        if (active)
            NetworkService.refresh();
        NetworkService.vpnStatsWanted = active;
    }

    readonly property bool wifiBusy: NetworkService.wifiConnecting || NetworkService.scanning

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
        editProc.command = ["bash", "-c", `nm-connection-editor --edit="$(nmcli -g connection.uuid connection show id ${ShellQuote.shQuote(ssid)})"`];
        editProc.running = false;
        editProc.running = true;
    }

    function btCardIcon() {
        const type = BluetoothService.materialIconFor(BluetoothService.firstConnected?.icon ?? "");
        if (type === "headphones")
            return headphonesComp;
        if (type === "phone")
            return phoneComp;
        if (type === "keyboard")
            return keyboardComp;
        return btIconComp;
    }

    function btRowIcon(iconStr) {
        const type = BluetoothService.materialIconFor(iconStr);
        if (type === "headphones")
            return btRowHeadphones;
        if (type === "phone")
            return btRowPhone;
        return btRowGeneric;
    }

    Process {
        id: editProc
    }

    Component {
        id: ethIconComp
        MaterialIcon {
            name: "ethernet"
            iconSize: 22
            filled: NetworkService.ethConnected
            color: NetworkService.ethConnected ? Colors.md3.on_tertiary_container : Colors.md3.outline
        }
    }

    Component {
        id: wifiIconComp
        WifiIcon {
            iconSize: 22
            mode: NetworkService.wifiConnected ? "wifi" : (NetworkService.wifiEnabled ? "no-signal" : "disconnected")
            strength: NetworkService.wifiConnected ? NetworkService.wifiSignal : 0
            secured: (NetworkService.activeNetwork?.security ?? "").length > 0
            color: NetworkService.wifiEnabled ? Colors.md3.on_primary_container : Colors.md3.outline
        }
    }

    Component {
        id: btIconComp
        BluetoothIcon {
            iconSize: 22
            color: BluetoothService.enabled ? Colors.md3.on_secondary_container : Colors.md3.outline
            enabled: BluetoothService.enabled
            discovering: BluetoothService.discovering
        }
    }

    Component {
        id: headphonesComp
        MaterialIcon {
            name: "headphones"
            iconSize: 22
            color: Colors.md3.on_secondary_container
            filled: true
        }
    }

    Component {
        id: phoneComp
        MaterialIcon {
            name: "phone"
            iconSize: 22
            color: Colors.md3.on_secondary_container
            filled: true
        }
    }

    Component {
        id: keyboardComp
        MaterialIcon {
            name: "keyboard"
            iconSize: 22
            color: Colors.md3.on_secondary_container
            filled: true
        }
    }

    Component {
        id: btRowHeadphones
        MaterialIcon {
            name: "headphones"
            iconSize: 20
            color: Colors.md3.on_surface
            filled: true
        }
    }

    Component {
        id: btRowPhone
        MaterialIcon {
            name: "phone"
            iconSize: 20
            color: Colors.md3.on_surface
            filled: true
        }
    }

    Component {
        id: btRowGeneric
        BluetoothIcon {
            iconSize: 20
            color: Colors.md3.on_surface
            enabled: BluetoothService.enabled
            discovering: BluetoothService.discovering
        }
    }

    NetworkCard {
        Layout.fillWidth: true
        enabled: NetworkService.ethConnected
        tint: Colors.md3.tertiary_container
        tintColor: Colors.md3.on_tertiary_container
        iconComponent: ethIconComp
        title: Localization.t("networkPage.ethernet")
        subtitle: NetworkService.ethConnected ? Localization.t("networkPage.connected") : Localization.t("networkPage.not_connected")
        hasSwitch: NetworkService.ethAvailable
        switchChecked: NetworkService.ethConnected
        onSwitchToggled: NetworkService.toggleEthernet()
    }

    NetworkCard {
        id: wifiCard
        Layout.fillWidth: true
        enabled: NetworkService.wifiEnabled
        tint: Colors.md3.primary_container
        tintColor: Colors.md3.on_primary_container
        iconComponent: wifiIconComp
        title: NetworkService.wifiConnected ? NetworkService.wifiSsid : Localization.t("qsTileService.wifi")
        subtitle: NetworkService.wifiConnecting ? Localization.t("networkPage.connecting") : NetworkService.wifiConnected ? Localization.t("networkPage.strength_percent").arg(NetworkService.wifiSignal) : NetworkService.wifiEnabled ? Localization.t("networkPage.not_connected") : Localization.t("networkPage.off")
        hasSwitch: true
        switchChecked: NetworkService.wifiEnabled
        onSwitchToggled: NetworkService.toggle()
    }

    Spinner {
        Layout.fillWidth: true
        visible: running
        running: page.wifiBusy
        color: Colors.md3.secondary
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
                    text: Localization.t("networkPage.available_networks")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 24
                    width: scanTxt.implicitWidth + 14
                    radius: 12
                    color: (Config.dim(Colors.md3.surface_container_high))
                    visible: !NetworkService.scanning

                    Text {
                        id: scanTxt
                        anchors.centerIn: parent
                        text: Localization.t("networkPage.scan")
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
                    text: Localization.t("networkPage.scanning")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    visible: NetworkService.scanning
                }
            }
        }

        Repeater {
            id: netRepeater
            model: NetworkService.sortedNetworks

            delegate: Item {
                id: netRow
                required property var modelData
                required property int index

                property bool rowLoading: false

                readonly property bool askPw: NetworkService.awaitingPassword && NetworkService.pendingPasswordSsid === modelData.ssid
                property real pwProgress: askPw ? 1 : 0
                Behavior on pwProgress {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                function submitPw() {
                    if (!pwField.hasText || NetworkService.wifiConnecting)
                        return;
                    if (modelData.known)
                        NetworkService.changePassword(modelData.ssid, pwField.text);
                    else
                        NetworkService.connectWithPassword(modelData.ssid, pwField.text);
                }

                onAskPwChanged: {
                    if (askPw) {
                        rowLoading = false;
                        Qt.callLater(() => pwField.focusInput());
                    } else {
                        pwField.clear();
                    }
                }

                clip: true
                implicitWidth: parent?.width ?? 0
                implicitHeight: 52 + 52 * pwProgress

                Connections {
                    target: NetworkService
                    function onNetworksChanged() {
                        rowLoading = false;
                    }
                    function onPasswordFailedChanged() {
                        if (NetworkService.passwordFailed && netRow.askPw) {
                            pwField.clear();
                            pwField.shake();
                            pwField.focusInput();
                        }
                    }
                }

                RowLayout {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 14
                    }
                    height: 52
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
                            text: netRow.askPw && NetworkService.wifiConnecting ? Localization.t("networkPage.connecting") : modelData.active ? Localization.t("networkPage.connected") : modelData.known ? Localization.t("networkPage.saved_percent").arg(modelData.strength) : modelData.strength + "%"
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
                            color: (Config.dim(Colors.md3.surface_container_high))
                            visible: modelData.known
                            opacity: 1 - netRow.pwProgress

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
                                enabled: !rowLoading && !netRow.askPw
                                onClicked: editConnection(modelData.ssid)
                            }
                            Tooltip {
                                text: Localization.t("networkPage.tooltip_edit_connection")
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: (Config.dim(Colors.md3.surface_container_high))
                            visible: modelData.known && !modelData.active
                            opacity: 1 - netRow.pwProgress

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.pixelSize: 15
                                color: Colors.md3.outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !rowLoading && !netRow.askPw
                                onClicked: {
                                    rowLoading = true;
                                    NetworkService.forgetNetwork(modelData.ssid);
                                }
                            }
                            Tooltip {
                                text: Localization.t("networkPage.tooltip_forget_network")
                            }
                        }

                        Rectangle {
                            id: connPill
                            readonly property bool pwBusy: netRow.askPw && NetworkService.wifiConnecting
                            readonly property bool pwIdle: netRow.askPw && !pwField.hasText
                            height: 28
                            width: connRow.implicitWidth + 16
                            radius: 14
                            color: pwIdle || pwBusy || modelData.active ? (Config.dim(Colors.md3.surface_container_high)) : Colors.md3.secondary_container
                            transform: Translate {
                                y: 52 * netRow.pwProgress
                            }

                            Row {
                                id: connRow
                                anchors.centerIn: parent
                                spacing: 6

                                LoadingSpinner {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: connPill.pwBusy
                                    running: visible
                                    size: 12
                                    color: Colors.md3.on_surface_variant
                                }

                                Text {
                                    id: connTxt
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: connPill.pwBusy ? Localization.t("networkPage.connecting") : modelData.active ? Localization.t("networkPage.disconnect") : Localization.t("networkPage.connect")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: modelData.active || connPill.pwIdle || connPill.pwBusy ? Colors.md3.on_surface_variant : Colors.md3.on_secondary_container
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !rowLoading
                                onClicked: {
                                    if (netRow.askPw) {
                                        netRow.submitPw();
                                    } else if (modelData.active) {
                                        rowLoading = true;
                                        NetworkService.disconnectNetwork(modelData.ssid);
                                    } else if (!modelData.known && (modelData.security ?? "").length > 0) {
                                        NetworkService.requestPassword(modelData.ssid);
                                    } else {
                                        rowLoading = true;
                                        NetworkService.connectNetwork(modelData.ssid);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: netRow.pwProgress > 0.01
                    opacity: netRow.pwProgress
                    anchors {
                        right: parent.right
                        rightMargin: 14
                    }
                    y: 12
                    height: 28
                    width: cancelTxt.implicitWidth + 16
                    radius: 14
                    color: (Config.dim(Colors.md3.surface_container_high))

                    Text {
                        id: cancelTxt
                        anchors.centerIn: parent
                        text: Localization.t("lockSurface.cancel")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: netRow.askPw && !NetworkService.wifiConnecting
                        onClicked: NetworkService.cancelPassword()
                    }
                }

                PasswordField {
                    id: pwField
                    visible: netRow.pwProgress > 0.01
                    opacity: netRow.pwProgress
                    x: 38
                    y: 58
                    width: parent.width - 38 - 112
                    implicitHeight: 40
                    height: 40
                    revealable: true
                    busy: NetworkService.wifiConnecting
                    error: NetworkService.passwordFailed
                    placeholder: Localization.t(NetworkService.passwordFailed ? "networkPage.wrong_password" : "networkPage.password_hint")
                    onTextChanged: if (hasText && NetworkService.passwordFailed)
                        NetworkService.passwordFailed = false
                    onAccepted: netRow.submitPw()
                }
            }
        }
    }

    NetworkCard {
        id: btCard
        Layout.fillWidth: true
        enabled: BluetoothService.enabled
        tint: Colors.md3.secondary_container
        tintColor: Colors.md3.on_secondary_container
        iconComponent: btCardIcon()
        title: BluetoothService.firstConnected?.name ?? Localization.t("qsTileService.bluetooth")
        subtitle: !BluetoothService.enabled ? Localization.t("networkPage.off") : BluetoothService.connectedDevices.length > 0 ? (BluetoothService.firstConnected?.batteryAvailable ? Localization.t("networkPage.connected_battery").arg(BluetoothService.batteryIcon(Math.round(BluetoothService.firstConnected.battery * 100))).arg(Math.round(BluetoothService.firstConnected.battery * 100)) : Localization.t("networkPage.connected")) : Localization.t("networkPage.no_devices_connected")
        hasSwitch: true
        switchChecked: BluetoothService.enabled
        onSwitchToggled: BluetoothService.toggle()
    }

    Spinner {
        Layout.fillWidth: true
        visible: running
        running: BluetoothService.anyDeviceBusy || BluetoothService.discovering
        color: Colors.md3.secondary
    }

    SectionCard {
        Layout.fillWidth: true
        visible: BluetoothService.enabled

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
                    text: Localization.t("networkPage.paired_devices")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 24
                    width: btScanTxt.implicitWidth + 14
                    radius: 12
                    color: (Config.dim(Colors.md3.surface_container_high))
                    visible: !BluetoothService.discovering

                    Text {
                        id: btScanTxt
                        anchors.centerIn: parent
                        text: Localization.t("networkPage.scan")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.setDiscovering(true)
                    }
                    Tooltip {
                        text: Localization.t("networkPage.tooltip_scan_devices")
                    }
                }

                Rectangle {
                    height: 24
                    width: btStopTxt.implicitWidth + 14
                    radius: 12
                    color: (Config.dim(Colors.md3.surface_container_high))
                    visible: BluetoothService.discovering

                    Text {
                        id: btStopTxt
                        anchors.centerIn: parent
                        text: Localization.t("networkPage.scanning")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.setDiscovering(false)
                    }
                    Tooltip {
                        text: Localization.t("networkPage.tooltip_stop_scanning")
                    }
                }
            }
        }

        Repeater {
            id: btRepeater
            model: BluetoothService.knownDevices

            delegate: Item {
                required property var modelData
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
                            text: modelData.connected ? (modelData.batteryAvailable ? Localization.t("networkPage.connected_battery").arg(BluetoothService.batteryIcon(Math.round(modelData.battery * 100))).arg(Math.round(modelData.battery * 100)) : Localization.t("networkPage.connected")) : Localization.t("networkPage.paired")
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: modelData.connected ? Colors.md3.primary : Colors.md3.outline
                        }
                    }

                    Row {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            readonly property bool busy: BluetoothService.isDeviceBusy(modelData)

                            height: 28
                            width: btConnTxt.implicitWidth + 16
                            radius: 14
                            bottomRightRadius: 6
                            topRightRadius: 6
                            color: modelData.connected ? (Config.dim(Colors.md3.surface_container_high)) : Colors.md3.secondary_container
                            opacity: busy ? 0.6 : 1.0

                            Text {
                                id: btConnTxt
                                anchors.centerIn: parent
                                text: modelData.state === BluetoothDeviceState.Connecting ? Localization.t("networkPage.connecting") : modelData.state === BluetoothDeviceState.Disconnecting ? Localization.t("networkPage.disconnecting") : modelData.connected ? Localization.t("networkPage.disconnect") : Localization.t("networkPage.connect")
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: modelData.connected ? Colors.md3.on_surface_variant : Colors.md3.on_secondary_container
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !parent.busy
                                onClicked: {
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
                            bottomLeftRadius: 6
                            topLeftRadius: 6
                            color: (Config.dim(Colors.md3.surface_container_high))

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.pixelSize: 15
                                color: Colors.md3.outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothService.forgetDevice(modelData)
                            }
                            Tooltip {
                                text: Localization.t("networkPage.tooltip_forget_device")
                            }
                        }
                    }
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("networkPage.available_devices")
        Layout.fillWidth: true
        visible: BluetoothService.enabled && BluetoothService.newDevices.length > 0

        Repeater {
            id: newBtRepeater
            model: BluetoothService.newDevices

            delegate: Item {
                required property var modelData
                required property int index

                implicitWidth: parent?.width ?? 0
                implicitHeight: 58

                readonly property bool nameIsMac: /^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$/.test(modelData.name)

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
                        opacity: 0.6

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
                            text: nameIsMac ? "Unknown device" : (modelData.name || "Unknown device")
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Colors.md3.on_surface
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.pairing ? "Pairing..." : nameIsMac ? modelData.name : modelData.address ?? ""
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: Colors.md3.outline
                        }
                    }

                    Rectangle {
                        height: 28
                        width: pairTxt.implicitWidth + 16
                        radius: 14
                        color: Colors.md3.secondary_container
                        opacity: modelData.pairing ? 0.5 : 1.0

                        Text {
                            id: pairTxt
                            anchors.centerIn: parent
                            text: modelData.pairing ? Localization.t("networkPage.pairing") : Localization.t("networkPage.pair")
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Colors.md3.on_secondary_container
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: !modelData.pairing
                            onClicked: BluetoothService.pairDevice(modelData)
                        }
                    }
                }
            }
        }
    }

    Labs.FileDialog {
        id: vpnFilePicker
        title: Localization.t("networkPage.vpn_import")
        fileMode: Labs.FileDialog.OpenFiles
        nameFilters: ["WireGuard (*.conf)"]
        onAccepted: NetworkService.vpnImport(vpnFilePicker.files)
    }

    component VpnPill: Rectangle {
        id: pill
        property string text: ""
        property string icon: ""
        property color fill: Config.dim(Colors.md3.surface_container_high)
        property color content: Colors.md3.on_surface_variant
        property bool dragHover: false
        property real outerLeft: 6
        property real outerRight: 6
        signal clicked

        height: 28
        width: pill.text !== "" ? pillRow.implicitWidth + 20 : 28
        topLeftRadius: outerLeft
        bottomLeftRadius: outerLeft
        topRightRadius: outerRight
        bottomRightRadius: outerRight
        color: pill.dragHover ? Colors.md3.primary_container : pill.fill

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                visible: pill.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: pill.icon
                iconSize: 16
                color: pill.dragHover ? Colors.md3.on_primary_container : pill.content
                transitionType: "none"
            }
            Text {
                visible: pill.text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: pill.dragHover ? Colors.md3.on_primary_container : pill.content
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    Component {
        id: vpnIconComp
        MaterialIcon {
            name: "shield-lock"
            iconSize: 22
            filled: NetworkService.vpnConnected
            color: NetworkService.vpnConnected ? Colors.md3.on_tertiary_container : Colors.md3.outline
        }
    }

    NetworkCard {
        Layout.fillWidth: true
        enabled: NetworkService.vpnConnected
        tint: Colors.md3.tertiary_container
        tintColor: Colors.md3.on_tertiary_container
        iconComponent: vpnIconComp
        title: NetworkService.vpnConnected ? NetworkService.vpnName : Localization.t("qsTileService.vpn")
        subtitle: NetworkService.vpnConnected ? (NetworkService.vpnSubtitle(NetworkService.vpnActive[0]) || Localization.t("networkPage.connected")) : NetworkService.vpnProfiles.length === 0 ? Localization.t("qsTileService.vpn_none") : Localization.t("networkPage.not_connected")
        hasSwitch: NetworkService.vpnProfiles.length > 0
        switchChecked: NetworkService.vpnConnected
        onSwitchToggled: NetworkService.toggleVpn()
    }

    SectionCard {
        Layout.fillWidth: true

        Item {
            implicitWidth: parent?.width ?? 0
            implicitHeight: 46

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 14
                }
                spacing: 8

                Text {
                    text: Localization.t("networkPage.vpn_profiles")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.fillWidth: true
                }

                VpnPill {
                    Layout.alignment: Qt.AlignVCenter
                    text: dragHover ? Localization.t("networkPage.vpn_drop") : Localization.t("networkPage.vpn_import")
                    icon: "add"
                    outerLeft: 14
                    outerRight: 14
                    onClicked: vpnFilePicker.open()
                    Tooltip {
                        text: Localization.t("networkPage.tooltip_vpn_import")
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["text/uri-list"]
                        onEntered: parent.dragHover = true
                        onExited: parent.dragHover = false
                        onDropped: drop => {
                            parent.dragHover = false;
                            NetworkService.vpnImport(drop.urls ?? []);
                        }
                    }
                }
            }
        }

        Repeater {
            id: vpnRepeater
            model: NetworkService.vpnProfiles

            delegate: Item {
                id: vpnRow
                required property var modelData
                required property int index
                property bool renaming: false

                implicitWidth: parent?.width ?? 0
                implicitHeight: 58

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 14
                    }
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 34
                        height: 34
                        radius: 17
                        color: vpnRow.modelData.active ? Colors.md3.tertiary_container : Config.dim(Colors.md3.surface_container_high)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: "shield-lock"
                            iconSize: 18
                            filled: vpnRow.modelData.active
                            color: vpnRow.modelData.active ? Colors.md3.on_tertiary_container : Colors.md3.outline
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            visible: !vpnRow.renaming
                            text: vpnRow.modelData.name
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: vpnRow.modelData.active ? Font.Medium : Font.Normal
                            color: Colors.md3.on_surface
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        TextInputField {
                            id: renameField
                            visible: vpnRow.renaming
                            Layout.fillWidth: true
                            implicitHeight: 30
                            text: vpnRow.modelData.name
                            onCommitted: t => {
                                NetworkService.vpnRename(vpnRow.modelData.uuid, t);
                                vpnRow.renaming = false;
                            }
                        }

                        Text {
                            visible: !vpnRow.renaming && text !== ""
                            text: NetworkService.vpnSubtitle(vpnRow.modelData)
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: vpnRow.modelData.active ? Colors.md3.primary : Colors.md3.outline
                        }
                    }

                    Row {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        VpnPill {
                            text: vpnRow.modelData.active ? Localization.t("networkPage.disconnect") : Localization.t("networkPage.connect")
                            outerLeft: 14
                            fill: vpnRow.modelData.active ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.secondary_container
                            content: vpnRow.modelData.active ? Colors.md3.on_surface_variant : Colors.md3.on_secondary_container
                            onClicked: vpnRow.modelData.active ? NetworkService.vpnDisconnect(vpnRow.modelData.uuid) : NetworkService.vpnConnect(vpnRow.modelData.uuid)
                        }
                        VpnPill {
                            icon: "star"
                            text: vpnRow.modelData.boot ? Localization.t("networkPage.vpn_boot") : ""
                            fill: vpnRow.modelData.boot ? Colors.md3.tertiary_container : Config.dim(Colors.md3.surface_container_high)
                            content: vpnRow.modelData.boot ? Colors.md3.on_tertiary_container : Colors.md3.on_surface_variant
                            onClicked: NetworkService.vpnSetBoot(vpnRow.modelData.uuid)
                            Tooltip {
                                text: vpnRow.modelData.boot ? Localization.t("networkPage.tooltip_vpn_boot_disable") : Localization.t("networkPage.tooltip_vpn_boot_enable")
                            }
                        }
                        VpnPill {
                            icon: vpnRow.renaming ? "check" : "edit"
                            onClicked: vpnRow.renaming ? renameField.commit() : vpnRow.renaming = true
                            Tooltip {
                                text: vpnRow.renaming ? "" : Localization.t("networkPage.tooltip_vpn_rename")
                            }
                        }
                        VpnPill {
                            icon: "delete"
                            outerRight: 14
                            onClicked: NetworkService.vpnDelete(vpnRow.modelData.uuid)
                            Tooltip {
                                text: Localization.t("networkPage.tooltip_vpn_delete")
                            }
                        }
                    }
                }
            }
        }
    }
}
