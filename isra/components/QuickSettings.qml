import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets

import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property var panelWindow

    readonly property string panelType: "quicksettings"
    property var registry: null
    property var controllerRegistry: null

    implicitWidth: button.width
    height: button.height

    property bool isOpen: false
    readonly property bool suppressNotificationPopups: true
    property bool editMode: false
    property bool _instantHidden: false

    property bool _editVisual: false
    readonly property bool _showNormal: !editMode && !_editVisual
    readonly property bool _showEdit: editMode && _editVisual
    onEditModeChanged: editFadeTimer.restart()

    Timer {
        id: editFadeTimer
        interval: 160
        onTriggered: root._editVisual = root.editMode
    }

    function _iconVisible(id) {
        if (id === "sound")
            return root._soundConfigured || root._soundForced;
        return Config.quicksettings.icons.includes(id);
    }

    function _iconActive(id) {
        if (!root._iconVisible(id))
            return false;
        switch (id) {
        case "wifi": return true;
        case "bluetooth": return BluetoothService.enabled;
        case "sound": return true;
        case "caffeine": return CaffeineService.active;
        case "nightlight": return NightLightService.active;
        case "dnd": return NotificationService.dnd;
        case "recording": return ScreencapService.isRecording;
        case "vpn": return NetworkService.vpnConnected;
        case "mic": return AudioService.micInUse;
        case "screenshare": return ScreenShareService.active;
        case "traffic": return true;
        case "dns": return DnsService.enabled;
        case "gamemode": return GameModeService.active;
        case "powerprofile": return true;
        default: return false;
        }
    }

    function _iconOverrideColor(id) {
        return id === "recording" || id === "mic" || id === "screenshare";
    }

    function _iconComponentFor(id) {
        switch (id) {
        case "wifi": return wifiIconComp;
        case "bluetooth": return bluetoothIconComp;
        case "sound": return soundIconComp;
        case "caffeine": return caffeineIconComp;
        case "nightlight": return nightlightIconComp;
        case "dnd": return dndIconComp;
        case "recording": return recordingIconComp;
        case "vpn": return vpnIconComp;
        case "mic": return micIconComp;
        case "screenshare": return screenshareIconComp;
        case "traffic": return trafficIconComp;
        case "dns": return dnsIconComp;
        case "gamemode": return gamemodeIconComp;
        case "powerprofile": return powerprofileIconComp;
        default: return null;
        }
    }

    readonly property bool _soundConfigured: Config.quicksettings.icons.includes("sound")
    readonly property bool _soundForced: !root._soundConfigured && AudioService.muted

    readonly property var _canonicalIconOrder: ["wifi", "bluetooth", "sound", "caffeine", "nightlight", "dnd", "recording", "vpn", "mic", "screenshare", "traffic", "dns", "gamemode", "powerprofile"]

    function _formatRate(bytesPerSec) {
        if (bytesPerSec >= 1073741824) return (bytesPerSec / 1073741824).toFixed(1) + "GB/s";
        if (bytesPerSec >= 1048576) return (bytesPerSec / 1048576).toFixed(1) + "MB/s";
        if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + "KB/s";
        return Math.round(bytesPerSec) + "B/s";
    }

    function _iconLabel(id) {
        switch (id) {
        case "traffic": return root._formatRate(NetworkTrafficService.rxBytesPerSec + NetworkTrafficService.txBytesPerSec);
        default: return "";
        }
    }

    readonly property var _baselineIconIds: ["wifi", "traffic", "powerprofile", "sound"]
    readonly property bool _anyIconActive: AudioService.muted || root._canonicalIconOrder.some(id => !root._baselineIconIds.includes(id) && root._iconActive(id))

    function toggleSelf(): void {
        root.isOpen = !root.isOpen;
        if (root.isOpen)
            NotificationService.sendAllToPanel();
    }

    function close(): void {
        root.isOpen = false;
    }

    function closeInstantly(): void {
        root._instantHidden = true;
        root.isOpen = false;
    }

    onIsOpenChanged: {
        if (isOpen) {
            _instantHidden = false;
            PanelService.opened(root, root.panelWindow?.screen);
        } else {
            PanelService.closed(root);
            root.editMode = false;
        }
    }

    Component.onCompleted: Qt.callLater(() => {
        PanelService.register(root, root.controllerRegistry, root.registry, root.panelWindow?.screen?.name ?? "");
    })

    Rectangle {
        id: button
        color: {
            if (root.isOpen) {
                Colors.md3.secondary_container
            } else if (Config.bar.transparentPills) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else {
                Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
            }
        }
        radius: 18
        implicitWidth: btnRow.implicitWidth + 10
        height: 32

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 0
            leftPadding: (root._anyIconActive || liveBatteryWidget.visible) ? 5 : 2

            Repeater {
                model: root._canonicalIconOrder
                delegate: StatusIcon {
                    required property string modelData
                    active: root._iconActive(modelData)
                    overrideColor: root._iconOverrideColor(modelData)
                    iconComponent: root._iconComponentFor(modelData)
                    extraLabel: root._iconLabel(modelData)
                }
            }

            Item {
                width: liveBatteryWidget.width + 4
                height: liveBatteryWidget.height
                visible: BatteryService.hasBattery

                readonly property int marginLeft: 4
                readonly property int marginRight: 6
                BatteryIcon {
                    id: liveBatteryWidget
                    anchors.left: parent.left
                    anchors.leftMargin: parent.marginLeft
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                implicitWidth: (root._anyIconActive || liveBatteryWidget.visible) ? 12 : 0
                height: 14
                color: "transparent"
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 14
                    color: root.isOpen | Config.bar.transparency === 2 ? Colors.md3.on_secondary_container : Colors.md3.outline_variant
                    opacity: 0.3

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
            }

            Item {
                implicitWidth: 26
                height: 24

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: Colors.md3.primary_container
                    visible: btnProfileImage.status !== Image.Ready
                }

                ClippingRectangle {
                    anchors.centerIn: parent
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    clip: true
                    layer.enabled: true
                    layer.smooth: true
                    antialiasing: true
                    visible: btnProfileImage.status === Image.Ready
                    color: "transparent"

                    Image {
                        id: btnProfileImage
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        anchors.fill: parent
                        sourceSize: Qt.size(40, 40)
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        smooth: true
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleSelf()
        }
    }

    Component {
        id: wifiIconComp
        WifiIcon {
            iconSize: 16
            filled: !Config.quicksettings.outline
            mode: (NetworkService.wifiEnabled && NetworkService.wifiConnected) ? "wifi" : (NetworkService.ethConnected ? "ethernet" : "disconnected")
            strength: NetworkService.wifiSignal
            secured: {
                if (!NetworkService.activeNetwork) return false;
                const sec = NetworkService.activeNetwork.security;
                return sec !== "" && sec !== "--";
            }
        }
    }

    Component {
        id: bluetoothIconComp
        BluetoothIcon {
            iconSize: 16
            enabled: true
            discovering: (Bluetooth.defaultAdapter?.discovering ?? false) ||
                        Bluetooth.devices.values.some(d => d.connecting)
            connected: BluetoothService.connectedDevices.length > 0
        }
    }

    Component {
        id: soundIconComp
        Item {
            id: soundWrap
            implicitWidth: 16
            implicitHeight: 16
            property color color: "white"
            readonly property color displayColor: AudioService.muted ? Colors.md3.error : soundWrap.color
            readonly property bool isHeadphones: AudioService.sinkIsHeadphones
            VolumeIcon {
                anchors.fill: parent
                visible: !soundWrap.isHeadphones
                color: soundWrap.displayColor
                muted: AudioService.muted
                volume: Math.round(AudioService.volume * 100)
                filled: !Config.quicksettings.outline
            }
            MaterialIcon {
                anchors.fill: parent
                visible: soundWrap.isHeadphones
                name: "headphones"
                filled: !Config.quicksettings.outline
                color: soundWrap.displayColor
            }
        }
    }

    Component {
        id: caffeineIconComp
        MaterialIcon {
            name: "caffeine"
            iconSize: 16
            filled: !Config.quicksettings.outline
        }
    }

    Component {
        id: nightlightIconComp
        MaterialIcon {
            name: "nightlight"
            iconSize: 16
            filled: !Config.quicksettings.outline
        }
    }

    Component {
        id: dndIconComp
        MaterialIcon {
            name: "dnd"
            iconSize: 16
            filled: !Config.quicksettings.outline
        }
    }

    Component {
        id: recordingIconComp
        MaterialIcon {
            name: "record"
            iconSize: 16
            filled: !Config.quicksettings.outline
            color: Colors.md3.error
        }
    }

    Component {
        id: vpnIconComp
        MaterialIcon {
            name: "shield-lock"
            iconSize: 16
            filled: !Config.quicksettings.outline
        }
    }

    Component {
        id: micIconComp
        MaterialIcon {
            name: "mic"
            iconSize: 16
            filled: !Config.quicksettings.outline
            color: Colors.md3.error
        }
    }

    Component {
        id: screenshareIconComp
        MaterialIcon {
            name: "cast"
            iconSize: 16
            filled: !Config.quicksettings.outline
            color: Colors.md3.error
        }
    }

    Component {
        id: trafficIconComp
        MaterialIcon {
            name: "mobiledata-arrows"
            iconSize: 16
        }
    }

    Component {
        id: dnsIconComp
        DnsProviderIcon {
            iconSize: 16
            provider: DnsService.currentProvider.id
        }
    }

    Component {
        id: gamemodeIconComp
        MaterialIcon {
            name: "game-mode"
            iconSize: 16
            filled: !Config.quicksettings.outline
        }
    }

    Component {
        id: powerprofileIconComp
        PowerProfileIcon {
            iconSize: 16
            profileMode: PowerProfileService.profileIndex
            filled: !Config.quicksettings.outline
        }
    }

    component StatusIcon: Item {
        id: statusRoot
        property bool active: true
        property Component iconComponent: null
        property bool overrideColor: false
        property color iconColor: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
        property string extraLabel: ""
        readonly property bool hasLabel: extraLabel.length > 0

        implicitWidth: active ? (26 + (hasLabel ? labelText.implicitWidth + 2 : 0)) : 0
        height: 24
        clip: true
        opacity: active ? 1 : 0
        scale: active ? 1 : 0.4

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 2

            Loader {
                id: statusIconLoader
                sourceComponent: statusRoot.iconComponent
                visible: statusRoot.iconComponent !== null

                Binding {
                    target: statusIconLoader.item
                    property: "color"
                    value: statusRoot.iconColor
                    when: !statusRoot.overrideColor && statusIconLoader.status === Loader.Ready && statusIconLoader.item && statusIconLoader.item.hasOwnProperty("color")
                }
            }

            Text {
                id: labelText
                visible: statusRoot.hasLabel
                text: statusRoot.extraLabel
                anchors.verticalCenter: parent.verticalCenter
                font.family: Config.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
                color: statusRoot.iconColor
                font.features: ({ "tnum": 1 })
            }
        }
    }
}
