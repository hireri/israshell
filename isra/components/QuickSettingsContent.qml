pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    anchors.fill: parent

    Process {
        id: appletProc
    }
    Process {
        id: sysProc
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.isOpen
        Keys.onEscapePressed: event => {
            event.accepted = true;
            if (root.controller)
                root.controller.isOpen = false;
        }
    }

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => root._ready = true)

    Rectangle {
        id: sidebarCard
        visible: !(root.controller?._instantHidden ?? false)
        width: 420
        height: 786
        radius: 18
        color: Qt.alpha(Colors.md3.surface_container_low, Config.blurOpacity)
        border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
        border.width: 1
        clip: true

        anchors {
            right: parent.right
            rightMargin: (root._ready && root.isOpen) ? 12 : -440
            top: Config.bar.position === 0 ? parent.top : undefined
            bottom: Config.bar.position === 1 ? parent.bottom : undefined
            topMargin: Config.bar.position === 0 ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : 8
            bottomMargin: Config.bar.position === 1 ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : 8
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Item {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.preferredHeight: 44

            RowLayout {
                id: userRow
                anchors.fill: parent
                spacing: 12
                opacity: (root.controller?._showNormal ?? false) ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    ClippingRectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
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
                            sourceSize: Qt.size(108, 108)
                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                            mipmap: true
                        }
                    }

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: Colors.md3.primary_container
                        visible: profileImage.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: SystemInfo.username ? SystemInfo.username.charAt(0).toUpperCase() : "U"
                            color: Colors.md3.on_primary_container
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: SystemInfo.username
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: SystemInfo.hostname + " · " + SystemInfo.uptime
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    id: actionsPill
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: actionsRow.implicitWidth + 4
                    implicitHeight: 36
                    radius: height / 2
                    color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                    Row {
                        id: actionsRow
                        anchors.centerIn: parent
                        spacing: 2

                        ActionIconBtn {
                            btnIcon: "edit"
                            onBtnClicked: if (root.controller)
                                root.controller.editMode = true
                        }

                        ActionIconBtn {
                            btnIcon: "restart"
                            onBtnClicked: {
                                if (root.controller)
                                    root.controller.isOpen = false;
                                Quickshell.execDetached(["bash", "-c", "kill $(pidof quickshell); sleep 0.1; qs -n -c isra"]);
                            }
                        }

                        ActionIconBtn {
                            btnIcon: "settings"
                            onBtnClicked: {
                                if (root.controller)
                                    root.controller.isOpen = false;
                                sysProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"];
                                sysProc.running = true;
                            }
                        }

                        ActionIconBtn {
                            id: userRowRight
                            btnIcon: "shutdown"
                            danger: true
                            onBtnClicked: {
                                if (root.controller)
                                    root.controller.isOpen = false;
                                PowerMenuState.toggle();
                            }
                        }
                    }
                }
            }

            RowLayout {
                id: editHeaderRow
                anchors.fill: parent
                opacity: (root.controller?._showEdit ?? false) ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: height / 2
                    color: backMouse.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MaterialIcon {
                        name: "arrow-back"
                        anchors.centerIn: parent
                        iconSize: 16
                        color: backMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (root.controller)
                            root.controller.editMode = false
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    horizontalAlignment: Text.AlignLeft
                    text: Localization.t("quickSettings.edit_tiles")
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    color: Colors.md3.on_surface
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    height: 36
                    radius: height / 2
                    implicitWidth: resetRow.implicitWidth + 24
                    color: resetMouse.containsMouse ? Qt.lighter(Colors.md3.primary, 1.1) : Colors.md3.primary

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Row {
                        id: resetRow
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialIcon {
                            name: "restart"
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: 16
                            color: Colors.md3.on_primary
                        }

                        Text {
                            text: Localization.t("quickSettings.reset")
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.md3.on_primary
                            renderType: Text.NativeRendering
                        }
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({ quickSettingsTiles: QsTileService.defaultLayout() })
                    }
                }
            }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: qsCol.implicitHeight + 28
                color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                radius: 24

                ColumnLayout {
                    id: qsCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

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
                                if (root.controller)
                                    root.controller.isOpen = false;
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
                                if (root.controller)
                                    root.controller.isOpen = false;
                                appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", "display"];
                                appletProc.running = true;
                            }
                            dimmed: false
                        }
                    }

                    QsTileGrid {
                        Layout.fillWidth: true
                        editMode: root.controller?.editMode ?? false
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
                    color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                    topRightRadius: 22
                    topLeftRadius: 22

                    RowLayout {
                        id: notifHeaderRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 8
                            rightMargin: 8
                            topMargin: 8
                            bottomMargin: 0
                        }
                        spacing: 4
                        opacity: (root.controller?._showNormal ?? false) ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Rectangle {
                            readonly property bool isHeld: dndMouse.pressed && dndMouse.containsMouse

                            Layout.preferredWidth: isHeld ? 64 : 56
                            Layout.fillHeight: true
                            radius: 10
                            topLeftRadius: 18
                            color: dndMouse.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on Layout.preferredWidth {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MaterialIcon {
                                name: "dnd"
                                anchors.centerIn: parent
                                iconSize: 16
                                color: Colors.md3.on_surface
                                filled: NotificationService.dnd
                                transitionType: "circle"
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
                            color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
                            Text {
                                anchors.centerIn: parent
                                text: NotificationService.qsGroupModel.count === 0 ? Localization.t("quickSettings.no_notifications") : NotificationService.qsGroupModel.count === 1 ? Localization.t("quickSettings.one_notification") : Localization.t("quickSettings.notifications_count").arg(NotificationService.qsGroupModel.count)
                                font.pixelSize: 13
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                color: Colors.md3.on_surface
                                renderType: Text.NativeRendering
                            }
                        }

                        Rectangle {
                            readonly property bool isHeld: clearMouse.pressed && clearMouse.containsMouse

                            Layout.preferredWidth: isHeld ? 64 : 56
                            Layout.fillHeight: true
                            radius: 10
                            topRightRadius: 18
                            color: clearMouse.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
                            opacity: NotificationService.qsGroupModel.count > 0 ? 1 : 0.3

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on Layout.preferredWidth {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MaterialIcon {
                                name: "clear-all"
                                anchors.centerIn: parent
                                iconSize: 16
                                filled: NotificationService.qsGroupModel.count > 0
                                color: Colors.md3.on_surface
                                transitionType: "wipe-up"
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

                    Rectangle {
                        id: editHeaderTile
                        anchors.fill: parent
                        anchors {
                            leftMargin: 8
                            rightMargin: 8
                            topMargin: 8
                            bottomMargin: 0
                        }
                        radius: 10
                        topLeftRadius: 18
                        topRightRadius: 18
                        color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
                        opacity: (root.controller?._showEdit ?? false) ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Text {
                            anchors.centerIn: parent
                            readonly property int availableCount: (Config.quickSettingsTiles?.removed ?? []).length
                            text: availableCount === 0
                                ? Localization.t("quickSettings.no_tiles_available")
                                : availableCount === 1
                                    ? Localization.t("quickSettings.one_tile_available")
                                    : Localization.t("quickSettings.tiles_available_count").arg(availableCount)
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                            renderType: Text.NativeRendering
                        }
                    }
                }

                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 24
                    topRightRadius: 0
                    topLeftRadius: 0
                    color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                    clip: true

                    Column {
                        id: caughtUpCol
                        anchors.centerIn: parent
                        spacing: 12
                        readonly property bool isAllCaughtUp: NotificationService.qsGroupModel.count === 0

                        opacity: (isAllCaughtUp && (root.controller?._showNormal ?? false)) ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        transform: Translate {
                            y: caughtUpCol.isAllCaughtUp ? 0 : 25
                            Behavior on y {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 200
                            implicitHeight: 80
                            radius: 24
                            color: Colors.md3.primary_container

                            Text {
                                anchors.centerIn: parent
                                text: "(˶˃ ᵕ ˂˶) .ᐟ.ᐟ"
                                font.pixelSize: 32
                                renderType: Text.NativeRendering
                                color: Colors.md3.on_primary_container
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Localization.t("quickSettings.all_caught_up")
                            font.pixelSize: 16
                            renderType: Text.NativeRendering
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
                        opacity: (root.controller?._showNormal ?? false) ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
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

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: removedTray.implicitHeight
                        clip: false
                        opacity: (root.controller?._showEdit ?? false) ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        QsRemovedTray {
                            id: removedTray
                            width: parent.width
                        }
                    }
                }
            }
        }
    }

    component ActionIconBtn: Rectangle {
        id: aBtn
        property string btnIcon: ""
        property bool danger: false
        signal btnClicked

        width: 32
        height: 32
        radius: width / 2
        color: aBtnMA.containsMouse
            ? (aBtn.danger ? Colors.md3.error : Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity))
            : Qt.alpha(Colors.md3.surface_container_highest, 0)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MaterialIcon {
            name: aBtn.btnIcon
            anchors.centerIn: parent
            iconSize: 16
            color: aBtnMA.containsMouse ? (aBtn.danger ? Colors.md3.on_error : Colors.md3.on_surface) : Colors.md3.on_surface_variant
        }

        MouseArea {
            id: aBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: aBtn.btnClicked()
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

            color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
}
