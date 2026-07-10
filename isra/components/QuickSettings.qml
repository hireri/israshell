import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Services.UPower

import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property var panelWindow

    implicitWidth: button.width
    height: button.height

    property bool isOpen: false
    property bool _sidebarVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            _sidebarVisible = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 310
        onTriggered: if (!root.isOpen)
            root._sidebarVisible = false
    }

    GlobalShortcut {
        name: "openQuickSettings"
        description: "Toggle quick settings sidebar"
        onPressed: {
            const screen = root.panelWindow.screen;
            if (!screen)
                return;
            if (Hyprland.focusedMonitor?.name !== screen.name)
                return;
            root.isOpen = !root.isOpen;
            if (root.isOpen)
                NotificationService.sendAllToPanel();
        }
    }

    Rectangle {
        id: button
        color: {
            if (root.isOpen) {
                Colors.md3.secondary_container
            } else if (Config.transparentPills) {
                Config.transparentBar ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container
            } else { 
                Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
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
                iconComponent: CaffeineIcon {
                    iconSize: 16
                    filled: true
                }
            }
            StatusIcon {
                active: NightLightService.active
                iconComponent: NightlightIcon {
                    iconSize: 16
                    filled: true
                }
            }
            StatusIcon {
                active: NotificationService.dnd
                iconComponent: DndIcon {
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
                    color: root.isOpen | Config.transparentBar === 2 ? Colors.md3.on_secondary_container : Colors.md3.outline_variant
                    opacity: root.isOpen | Config.transparentBar ? 0.3 : 0.7

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
            onClicked: {
                root.isOpen = !root.isOpen;
                if (root.isOpen)
                    NotificationService.sendAllToPanel();
            }
        }
    }

    HyprlandFocusGrab {
        windows: [sidebarLoader.item]
        active: root.isOpen && sidebarLoader.active
        onCleared: root.isOpen = false
    }

    LazyLoader {
        id: sidebarLoader
        active: root._sidebarVisible

        PopupWindow {
            id: sidebar
            anchor.window: root.panelWindow
            anchor.rect.x: (root.panelWindow.screen?.width ?? 1920) - implicitWidth
            anchor.rect.y: Config.barPosition === 1 ? -((root.panelWindow.screen?.height ?? 1080) * 0.75 + (Config.transparentBar === 2 ? 0 : 12)) : root.panelWindow.height + (Config.transparentBar === 2 ? 0 : 12)

            implicitWidth: 432
            anchor.adjustment: PopupAdjustment.None
            implicitHeight: Math.round((root.panelWindow.screen?.height ?? 1080) * 0.75)
            color: "transparent"
            visible: root._sidebarVisible

            onVisibleChanged: {
                if (visible)
                    keyHandler.forceActiveFocus();
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                Keys.onEscapePressed: event => {
                    event.accepted = true;
                    root.isOpen = false;
                }
            }

            property bool _ready: false
            Component.onCompleted: Qt.callLater(() => _ready = true)

            property real slideX: (_ready && root.isOpen) ? 0 : 452

            Behavior on slideX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: sidebarCard
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 12
                width: 420
                radius: 18
                color: Colors.md3.surface_container_low
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
                border.width: 1
                clip: true

                transform: Translate {
                    x: sidebar.slideX
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        id: userRow
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        Item {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: 22
                                clip: true
                                layer.enabled: true
                                layer.smooth: true
                                antialiasing: true
                                visible: profileImage.status === Image.Ready
                                color: "transparent"

                                Image {
                                    id: profileImage
                                    source: "file://" + Quickshell.env("HOME") + "/.face"
                                    anchors.fill: parent
                                    sourceSize: Qt.size(144, 144)
                                    fillMode: Image.PreserveAspectCrop
                                    antialiasing: true
                                    smooth: true
                                    mipmap: true
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: SystemInfo.username
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: SystemInfo.hostname + " · " + SystemInfo.uptime
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 12
                            color: reloadMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            RestartIcon {
                                anchors.centerIn: parent
                                iconSize: 16
                                color: reloadMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                            }

                            MouseArea {
                                id: reloadMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.isOpen = false;
                                    Quickshell.execDetached(["bash", "-c", "kill $(pidof quickshell); sleep 0.1; qs -n -c isra"]);
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 12
                            color: editMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            SettingsIcon {
                                anchors.centerIn: parent
                                iconSize: 16
                                color: editMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                            }

                            MouseArea {
                                id: editMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.isOpen = false;
                                    sysProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"];
                                    sysProc.running = true;
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 12
                            color: pwrMouse.containsMouse ? Colors.md3.error : Colors.md3.error_container

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            ShutdownIcon {
                                anchors.centerIn: parent
                                iconSize: 16
                                color: pwrMouse.containsMouse ? Colors.md3.on_error : Colors.md3.error
                            }

                            MouseArea {
                                id: pwrMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.isOpen = false;
                                    PowerMenuState.toggle();
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: qsCol.implicitHeight + 28
                        color: Colors.md3.surface_container
                        radius: 24

                        ColumnLayout {
                            id: qsCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                QsWideChip {
                                    active: NetworkService.wifiEnabled || NetworkService.ethConnected
                                    label: {
                                        if (NetworkService.wifiEnabled) {
                                            if (NetworkService.wifiConnecting)
                                                return "Connecting...";
                                            if (NetworkService.wifiConnected && NetworkService.wifiSsid !== "")
                                                return NetworkService.wifiSsid;
                                            return "Not Connected";
                                        }
                                        if (NetworkService.ethConnected)
                                            return "Ethernet";
                                        return "Wi-Fi Off";
                                    }
                                    sublabel: {
                                        if (NetworkService.wifiConnected)
                                            return NetworkService.wifiSignal + "% signal";
                                        if (NetworkService.ethConnected && !NetworkService.wifiEnabled)
                                            return "Wired";
                                        return "";
                                    }
                                    onToggled: NetworkService.toggle()
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "network"];
                                        appletProc.running = true;
                                    }

                                    iconComponent: WifiIcon {
                                        iconSize: 22
                                        mode: (NetworkService.wifiEnabled && NetworkService.wifiConnected) ? "wifi" : (NetworkService.ethConnected ? "ethernet" : "disconnected")
                                        strength: NetworkService.wifiSignal
                                        secured: {
                                            if (!NetworkService.activeNetwork) return false;
                                            const sec = NetworkService.activeNetwork.security;
                                            return sec !== "" && sec !== "--";
                                        }
                                    }
                                }

                                QsWideChip {
                                    active: BluetoothService.enabled
                                    
                                    iconComponent: BluetoothIcon {
                                        iconSize: 22
                                        connected: BluetoothService.connectedDevices.length > 0
                                        
                                        enabled: BluetoothService.enabled
                                        discovering: BluetoothService.discovering
                                    }
                      
                                    label: {
                                        if (!BluetoothService.enabled)
                                            return "Bluetooth Off";
                                        const dev = BluetoothService.firstConnected;
                                        if (dev)
                                            return dev.name;
                                        if (BluetoothService.discovering)
                                            return "Scanning...";
                                        return "Bluetooth On";
                                    }
                                    
                                    sublabel: {
                                        const dev = BluetoothService.firstConnected;
                                        if (dev && dev.battery > 0) {
                                            let pct = Math.round(dev.battery * 100);
                                            return BluetoothService.batteryIcon(pct) + " " + pct + "%";
                                        }
                                        
                                        const n = BluetoothService.connectedCount;
                                        if (n > 1)
                                            return n + " devices";
                                        return "";
                                    }
                                    
                                    onToggled: BluetoothService.toggle()
                                        
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "network"];
                                        appletProc.running = true;
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                QsToggleChip {
                                    active: CaffeineService.active
                                    iconComponent: CaffeineIcon {
                                        iconSize: 22
                                        filled: CaffeineService.active
                                    }
                                    onToggled: CaffeineService.toggle()
                                }

                                QsToggleChip {
                                    active: NightLightService.active
                                    iconComponent: NightlightIcon {
                                        iconSize: 22
                                        filled: NightLightService.active
                                    }
                                    onToggled: NightLightService.toggle()
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "display"];
                                        appletProc.running = true;
                                    }
                                }

                                QsPowerProfileChip {}
                                QsGameModeChip {}
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: Config.verticalQSSliders ? 1 : 2
                                columnSpacing: 8
                                rowSpacing: 8

                                QsSliderRow {
                                    Layout.fillWidth: true
                                    value: AudioService.volume
                                    onMoved: val => AudioService.setVolume(val)
                                    onMuteClicked: AudioService.toggleMute()
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "sound"];
                                        appletProc.running = true;
                                    }
                                    dimmed: AudioService.muted
                                }

                                QsSliderRow {
                                    id: brightnessSlider
                                    Layout.fillWidth: true
                                    iconSet: "brightness"
                                    value: BrightnessService.value
                                    from: BrightnessService.from
                                    to: BrightnessService.to
                                    onMoved: val => BrightnessService.setBrightness(val)
                                    onMuteClicked: BrightnessService.setBrightness(1.0)
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "display"];
                                        appletProc.running = true;
                                    }
                                    dimmed: false
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: Colors.md3.surface_container
                            topRightRadius: 22
                            topLeftRadius: 22

                            RowLayout {
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 8
                                    rightMargin: 8
                                    topMargin: 8
                                    bottomMargin: 0
                                }
                                spacing: 4

                            Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.fillHeight: true
                                    radius: 10
                                    topLeftRadius: 18
                                    color: dndMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    DndIcon {
                                        anchors.centerIn: parent
                                        iconSize: 16
                                        color: Colors.md3.on_surface
                                        filled: NotificationService.dnd
                                    }

                                    MouseArea {
                                        id: dndMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: NotificationService.dnd = !NotificationService.dnd
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 10
                                    color: Colors.md3.surface_container_high

                                    Text {
                                        anchors.centerIn: parent
                                        text: NotificationService.qsGroupModel.count === 0 ? "No notifications" : NotificationService.qsGroupModel.count + " notification" + (NotificationService.qsGroupModel.count === 1 ? "" : "s")
                                        font.pixelSize: 13
                                        font.family: Config.fontFamily
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_surface
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.fillHeight: true
                                    radius: 10
                                    topRightRadius: 18
                                    color: clearMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                    opacity: NotificationService.qsGroupModel.count > 0 ? 1 : 0.3

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    ClearAllIcon {
                                        anchors.centerIn: parent
                                        iconSize: 16
                                        filled: NotificationService.qsGroupModel.count > 0
                                        color: Colors.md3.on_surface
                                    }

                                    MouseArea {
                                        id: clearMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        enabled: NotificationService.qsGroupModel.count > 0
                                        onClicked: NotificationService.dismissAll()
                                    }
                                }
                            }
                        }

                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 24
                            topRightRadius: 0
                            topLeftRadius: 0
                            color: Colors.md3.surface_container
                            clip: true

                            Column {
                                anchors.centerIn: parent
                                spacing: 12
                                visible: NotificationService.qsGroupModel.count === 0

                                Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 80
                                    radius: 24
                                    color: Colors.md3.primary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: "(˶˃ ᵕ ˂˶) .ᐟ.ᐟ"
                                        font.pixelSize: 32
                                        color: Colors.md3.on_primary_container
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "All caught up . . !"
                                    font.pixelSize: 16
                                    font.family: Config.fontFamily
                                    color: Colors.md3.on_surface_variant
                                    opacity: 0.8
                                }
                            }

                            Flickable {
                                id: qsFlick
                                anchors.fill: parent
                                anchors.margins: 8
                                contentHeight: notifCol.implicitHeight
                                clip: false
                                flickableDirection: Flickable.VerticalFlick
                                flickDeceleration: 4000
                                maximumFlickVelocity: 1200
                                boundsBehavior: Flickable.DragAndOvershootBounds
                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AlwaysOff
                                }

                                Column {
                                    id: notifCol
                                    width: qsFlick.width
                                    spacing: 6

                                    NotificationListView {
                                        id: qsNotifList
                                        width: parent.width
                                        implicitHeight: contentHeight
                                        height: contentHeight
                                        model: NotificationService.qsGroupModel

                                        delegate: NotificationGroup {
                                            required property int index
                                            readonly property var row: qsNotifList.model.get(index) ?? {}
                                            appName: row.appName ?? ""
                                            groupSummary: row.groupSummary ?? ""
                                            groupIdx: index
                                            listRef: qsNotifList
                                            showAll: true
                                            inPanel: true
                                            popup: false
                                            width: qsNotifList.width
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: appletProc
    }
    Process {
        id: sysProc
    }
    Process {
        id: settingsProc
    }


    component QsWideChip: Rectangle {
        id: wideChip
        property string icon: ""
        property Component iconComponent: null 
        property string label: ""
        property string sublabel: ""
        property bool active: false
        signal toggled
        signal rightClicked

        property color iconColor: wideChip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant

        Behavior on iconColor {
            ColorAnimation { duration: 150 }
        }

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: active ? 24 : 32
        color: (bodyMouse.containsMouse || iconMouse.containsMouse) ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                id: iconContainer
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: wideChip.active ? 16 : 24
                color: wideChip.active ? Colors.md3.primary : Colors.md3.surface_container

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Loader {
                    id: wideIconLoader
                    anchors.centerIn: parent
                    sourceComponent: wideChip.iconComponent
                    visible: wideChip.iconComponent !== null

                    Binding {
                        target: wideIconLoader.item
                        property: "color"
                        value: wideChip.iconColor
                        when: wideIconLoader.status === Loader.Ready && wideIconLoader.item.hasOwnProperty("color")
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: wideChip.icon
                    font.pixelSize: 22
                    font.family: Config.fontFamily
                    color: wideChip.iconColor
                    visible: wideChip.iconComponent === null 
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: wideChip.toggled()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: wideChip.label
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: wideChip.sublabel
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    color: Colors.md3.on_surface_variant
                    elide: Text.ElideRight
                    visible: wideChip.sublabel !== ""
                }
            }
        }

        MouseArea {
            id: bodyMouse
            anchors.fill: parent
            anchors.leftMargin: 56
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: wideChip.rightClicked()
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: wideChip.rightClicked()
        }
    }

    component QsPowerProfileChip: Rectangle {
        id: ppChip

        readonly property var profileColors: [Colors.md3.secondary_container, Colors.md3.surface_container_high, Colors.md3.primary]
        readonly property var profileColorsHover: [Qt.lighter(Colors.md3.secondary_container, 1.12), Colors.md3.surface_container_highest, Colors.md3.primary]
        readonly property var profileTextColors: [Colors.md3.on_secondary_container, Colors.md3.on_surface_variant, Colors.md3.on_primary]
        readonly property int profileIndex: PowerProfileService.profileIndex

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: profileIndex === 2 ? 14 : (profileIndex === 0 ? 20 : 26)
        color: ppMouse.containsMouse
            ? ppChip.profileColorsHover[profileIndex]
            : ppChip.profileColors[profileIndex]

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        PowerProfileIcon {
            anchors.centerIn: parent
            iconSize: 20
            profileMode: ppChip.profileIndex
            color: ppChip.profileTextColors[ppChip.profileIndex]
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: ppMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton
                ? PowerProfileService.cycle(-1)
                : PowerProfileService.cycle(1)
        }
    }

    component QsGameModeChip: Rectangle {
        id: gmChip

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: GameModeService.active ? 18 : 26
        color: {
            if (GameModeService.active)
                return Colors.md3.primary;
            if (gmMouse.containsMouse)
                return Colors.md3.surface_container_highest;
            return Colors.md3.surface_container_high;
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        GameModeIcon {
            anchors.centerIn: parent
            iconSize: 22
            filled: GameModeService.active
            color: GameModeService.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        }

        MouseArea {
            id: gmMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: GameModeService.toggle()
        }
    }

    component QsToggleChip: Rectangle {
        id: chip
        property string icon: ""
        property Component iconComponent: null
        property bool active: false
        signal toggled
        signal rightClicked

        property color iconColor: chip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        readonly property bool hovered: mouseArea.containsMouse

        Behavior on iconColor {
            ColorAnimation {
                duration: 150
            }
        }

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: active ? 18 : 26

        color: Colors.md3.surface_container_high

        Behavior on radius {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        states: [
            State {
                name: "ACTIVE"
                when: chip.active
                PropertyChanges { target: chip; color: Colors.md3.primary }
            },
            State {
                name: "HOVERED"
                when: chip.hovered && !chip.active
                PropertyChanges { target: chip; color: Colors.md3.surface_container_highest }
            }
        ]

        transitions: [
            Transition {
                from: "*"; to: "*"
                ColorAnimation {
                    properties: "color"
                    duration: 150
                }
            }
        ]

        Loader {
            id: iconLoader
            anchors.centerIn: parent
            sourceComponent: chip.iconComponent
            visible: chip.iconComponent !== null

            Binding {
                target: iconLoader.item
                property: "color"
                value: chip.iconColor
                when: iconLoader.status === Loader.Ready && iconLoader.item.hasOwnProperty("color")
            }
        }

        Text {
            anchors.centerIn: parent
            text: chip.icon
            font.pixelSize: 22
            font.family: Config.fontFamily
            color: chip.iconColor
            visible: chip.iconComponent === null
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => mouse.button === Qt.RightButton ? chip.rightClicked() : chip.toggled()
        }
    }

    component QsSliderRow: Item {
        id: sliderRow
        property real value: 0
        property real from: 0
        property real to: 1.5
        property bool dimmed: false
        property string iconSet: "volume"
        signal moved(real val)
        signal muteClicked
        signal rightClicked
        property real _dragRatio: -1
        property real _displayRatio: _dragRatio >= 0 ? _dragRatio : ((to - from > 0) ? (value - from) / (to - from) : 0)

        readonly property color _iconColor: {
            if (dimmed)
                return Colors.md3.surface_container_highest;
            if (value > 1.0 && iconSet === "volume")
                return Colors.md3.on_error;
            return Colors.md3.on_primary;
        }

        Layout.fillWidth: true
        Layout.preferredHeight: 44

        readonly property bool isHovered: mouseArea.containsMouse || _dragRatio >= 0
        property real hoverProgress: isHovered ? 1.0 : 0.0
        readonly property bool hoverTransitionActive: hoverAnim.running

        Behavior on hoverProgress {
            NumberAnimation {
                id: hoverAnim
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        readonly property real minW: height
        readonly property real thumbW: hoverProgress * 4
        readonly property real gap: 2 + (hoverProgress * 2)
        readonly property real usableWidth: width - minW - thumbW - (gap * 2)
        readonly property bool textFitsInside: barLeft.width > (sliderRow.width - valueText.implicitWidth - 36)

        Rectangle {
            id: barLeft
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 8
            radius: 14
            bottomRightRadius: 8
            topRightRadius: 8
            
            width: minW + sliderRow._displayRatio * usableWidth
            color: sliderRow.dimmed ? Colors.md3.outline : (sliderRow.value > 1.005 && sliderRow.iconSet === "volume" ? Colors.md3.error : Colors.md3.primary)

            Behavior on width {
                enabled: !sliderRow.hoverTransitionActive && sliderRow._dragRatio < 0
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuart
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 75
                }
            }

            Loader {
                id: sliderIconLoader
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                
                sourceComponent: sliderRow.iconSet === "brightness" ? brightnessComp : volumeComp

                Component {
                    id: volumeComp
                    VolumeIcon {
                        iconSize: 22
                        color: sliderRow._iconColor
                        muted: sliderRow.dimmed
                        volume: Math.round(sliderRow.value * 100)
                    }
                }

                Component {
                    id: brightnessComp
                    BrightnessIcon {
                        iconSize: 22
                        color: sliderRow._iconColor
                        brightness: Math.round(sliderRow.value * 100)
                    }
                }
            }
        }

        Rectangle {
            id: thumbRect
            x: barLeft.width + sliderRow.gap
            anchors.verticalCenter: parent.verticalCenter
            width: sliderRow.thumbW
            height: parent.height
            radius: 2
            color: barLeft.color
            opacity: sliderRow.hoverProgress

            Behavior on color { ColorAnimation { duration: 75 } }
        }

        Rectangle {
            id: barRight
            anchors {
                left: thumbRect.right
                leftMargin: sliderRow.gap
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - 8
            radius: 14
            bottomLeftRadius: 8
            topLeftRadius: 8
            
            color: Colors.md3.surface_container_high
        }

        Text {
            id: valueText
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(sliderRow.value * 100) + "%"
            font.pixelSize: 13
            font.bold: true
            font.family: Config.fontFamily
            font.features: { "tnum": 1 }

            x: textFitsInside
                ? (barLeft.width - implicitWidth - 12)
                : (sliderRow.width - implicitWidth - 14)

            color: textFitsInside ? sliderRow._iconColor : Colors.md3.on_surface_variant

            Behavior on x {
                enabled: !sliderRow.hoverTransitionActive
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            property int pressedButton: Qt.NoButton
            property bool dragStarted: false
            property real startX: 0

            onWheel: wheel => sliderRow.moved(wheel.angleDelta.y > 0 ? Math.min(sliderRow.to, sliderRow.value + 0.05) : Math.max(sliderRow.from, sliderRow.value - 0.05))
            onPressed: mouse => {
                pressedButton = mouse.button;
                if (mouse.button === Qt.RightButton) {
                    sliderRow.rightClicked();
                    return;
                }
                if (mouse.button === Qt.MiddleButton) {
                    sliderRow.muteClicked();
                    return;
                }
                startX = mouse.x;
                dragStarted = false;
            }
            onPositionChanged: mouse => {
                if (!pressed || pressedButton !== Qt.LeftButton)
                    return;
                if (Math.abs(mouse.x - startX) > 4)
                    dragStarted = true;
                if (dragStarted) {
                    let maxClickX = width - sliderRow.gap - (sliderRow.thumbW / 2);
                    let ratio = Math.max(0, Math.min(1, (mouse.x - sliderRow.minW) / (maxClickX - sliderRow.minW)));
                    let val = sliderRow.from + ratio * (sliderRow.to - sliderRow.from);
                    
                    if (mouse.modifiers & Qt.ShiftModifier) {
                        val = Math.round(val / 0.05) * 0.05;
                        val = Math.max(sliderRow.from, Math.min(sliderRow.to, val));
                        ratio = (sliderRow.to - sliderRow.from > 0) ? (val - sliderRow.from) / (sliderRow.to - sliderRow.from) : 0;
                    }

                    sliderRow._dragRatio = ratio;
                    sliderRow.moved(val);
                }
            }
            onReleased: mouse => {
                if (pressedButton !== Qt.LeftButton)
                    return;
                if (!dragStarted) {
                    if (startX <= sliderRow.minW)
                        sliderRow.muteClicked();
                    else {
                        let maxClickX = width - sliderRow.gap - (sliderRow.thumbW / 2);
                        let ratio = Math.max(0, Math.min(1, (mouse.x - sliderRow.minW) / (maxClickX - sliderRow.minW)));
                        let val = sliderRow.from + ratio * (sliderRow.to - sliderRow.from);

                        if (mouse.modifiers & Qt.ShiftModifier) {
                            val = Math.round(val / 0.05) * 0.05;
                            val = Math.max(sliderRow.from, Math.min(sliderRow.to, val));
                        }

                        sliderRow.moved(val);
                    }
                }
                sliderRow._dragRatio = -1;
            }
        }
    }

    component StatusIcon: Item {
        property bool active: true
        property string icon: ""
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