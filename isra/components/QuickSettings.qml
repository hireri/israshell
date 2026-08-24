import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Services.UPower

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
            leftPadding: (Bluetooth.defaultAdapter?.enabled || AudioService.muted || CaffeineService.active || NightLightService.active || NotificationService.dnd) ? 5 : 2

            StatusIcon {
                iconComponent: WifiIcon {
                    iconSize: 16

                    mode: (NetworkService.wifiEnabled && NetworkService.wifiConnected) ? "wifi" : (NetworkService.ethConnected ? "ethernet" : "disconnected")
                    strength: NetworkService.wifiSignal

                    secured: {
                        if (!NetworkService.activeNetwork) return false;
                        const sec = NetworkService.activeNetwork.security;
                        return sec !== "" && sec !== "--";
                    }
                }
            }
            StatusIcon {
                active: BluetoothService.enabled
                iconComponent: BluetoothIcon {
                    iconSize: 16

                    enabled: true
                    discovering: (Bluetooth.defaultAdapter?.discovering ?? false) ||
                                Bluetooth.devices.values.some(d => d.connecting)
                    connected: BluetoothService.connectedDevices.length > 0
                }
            }
            StatusIcon {
                active: AudioService.muted
                overrideColor: true
                iconComponent: VolumeIcon {
                    iconSize: 16
                    color: Colors.md3.error
                    muted: true
                }
            }
            StatusIcon {
                active: CaffeineService.active
                iconComponent: MaterialIcon {
                    name: "caffeine"
                    iconSize: 16
                    filled: true
                }
            }
            StatusIcon {
                active: NightLightService.active
                iconComponent: MaterialIcon {
                    name: "nightlight"
                    iconSize: 16
                    filled: true
                }
            }
            StatusIcon {
                active: NotificationService.dnd
                iconComponent: MaterialIcon {
                    name: "dnd"
                    iconSize: 16
                    filled: true
                }
            }

            Item {
                width: liveBatteryWidget.width + 4
                height: liveBatteryWidget.height
                visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

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
                implicitWidth: (Bluetooth.defaultAdapter?.enabled || AudioService.muted || CaffeineService.active || NightLightService.active || NotificationService.dnd || liveBatteryWidget.visible) ? 12 : 0
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

    component StatusIcon: Item {
        property bool active: true
        property Component iconComponent: null
        property bool overrideColor: false
        property color iconColor: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface

        implicitWidth: active ? 26 : 0
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

        Loader {
            id: statusIconLoader
            anchors.centerIn: parent
            sourceComponent: parent.iconComponent
            visible: parent.iconComponent !== null

            Binding {
                target: statusIconLoader.item
                property: "color"
                value: statusIconLoader.parent.iconColor
                when: !statusIconLoader.parent.overrideColor && statusIconLoader.status === Loader.Ready && statusIconLoader.item && statusIconLoader.item.hasOwnProperty("color")
            }
        }
    }
}
