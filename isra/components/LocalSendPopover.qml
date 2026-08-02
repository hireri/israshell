import QtQuick
import QtQuick.Layouts
import Qt.labs.platform as Labs
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services
import qs.windows.components

Item {
    id: root

    required property var panelWindow
    required property var widgetItem

    readonly property real cardW: 360
    readonly property real cardR: 24

    readonly property var devices: LocalSendService.devices
    readonly property var attached: LocalSendService.attachedFiles

    readonly property bool showIncoming: !!LocalSendService.pendingIncoming
    readonly property bool showPin: !!LocalSendService.pinRequest
    readonly property bool showTransfer: LocalSendService.transferring
    readonly property bool showWaiting: LocalSendService.awaitingPeer
    readonly property bool busy: showIncoming || showPin || showTransfer || showWaiting

    readonly property bool showError: LocalSendService.resultIsError && !busy
    readonly property bool showDone: (LocalSendService.resultIsOk || LocalSendService.resultIsNeutral) && !busy
    readonly property bool showPicker: Config.localsend.enabled && !busy
    readonly property bool showDevices: showPicker

    readonly property bool isOpen: root._isOpen
    property bool _isOpen: false
    property bool _popupVisible: false

    property real _pillCenterX: 0

    function open() {
        const mapped = root.widgetItem.mapToItem(root.panelWindow.contentItem, root.widgetItem.width / 2, 0);
        _pillCenterX = mapped.x;
        _isOpen = true;
        _popupVisible = true;
        PanelService.opened(root, root.panelWindow.screen);
        LocalSendService.scanNow();
    }

    function close() {
        if (!root._isOpen)
            return;
        _isOpen = false;
        closeTimer.restart();
        PanelService.closed(root);
    }

    Timer {
        id: closeTimer
        interval: 380
        onTriggered: if (!root._isOpen)
            root._popupVisible = false
    }

    Labs.FileDialog {
        id: filePicker
        title: "Choose files to send"
        fileMode: Labs.FileDialog.OpenFiles
        onAccepted: {
            LocalSendService.attachFilesFromUrls(filePicker.files);
            root.open();
        }
        onRejected: root.open()
    }

    LazyLoader {
        active: root._popupVisible

        Variants {
            id: popupVariants
            model: Quickshell.screens

            PanelWindow {
                id: popup

                required property ShellScreen modelData
                screen: modelData

                readonly property bool isOwnScreen: modelData === root.panelWindow?.screen

                visible: root._popupVisible

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:localsend"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"

                readonly property bool blurEnabled: popup.isOwnScreen && Config.blurAllowed(popup.visible)
                BackgroundEffect.blurRegion: blurEnabled ? cardBlurRegion : null
                Region {
                    id: cardBlurRegion
                    item: card
                }

                property bool _ready: false
                Component.onCompleted: Qt.callLater(() => _ready = true)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Item {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        root.close();
                    }
                }

                Item {
                    id: wrapper
                    visible: popup.isOwnScreen
                    width: root.cardW
                    height: card.height

                    readonly property real screenEdgeMargin: 12

                    anchors {
                        top: Config.bar.position === 0 ? parent.top : undefined
                        bottom: Config.bar.position === 1 ? parent.bottom : undefined
                        topMargin: Config.bar.position === 0 ? root.panelWindow.implicitHeight + 8 : 0
                        bottomMargin: Config.bar.position === 1 ? root.panelWindow.implicitHeight + 8 : 0
                    }

                    function _clamp(value, min, max) {
                        return max >= min ? Math.max(min, Math.min(max, value)) : min;
                    }

                    function _screenWidth() {
                        return (root.panelWindow.screen && root.panelWindow.screen.width > 0) ? root.panelWindow.screen.width : popup.width;
                    }

                    x: {
                        const idealX = root._pillCenterX - (root.cardW / 2);
                        return Math.round(wrapper._clamp(idealX, screenEdgeMargin, wrapper._screenWidth() - root.cardW - screenEdgeMargin));
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => mouse.accepted = true
                    }

                    ClippingRectangle {
                        id: card
                        property bool _ready: false
                        Component.onCompleted: Qt.callLater(() => _ready = true)

                        width: root.cardW
                        height: content.implicitHeight + 2
                        radius: root.cardR

                        y: {
                            const open = _ready && root.isOpen;
                            const edgeMargin = root.panelWindow.implicitHeight;
                            if (Config.bar.position === 0)
                                return open ? 0 : -(height + edgeMargin + 8);
                            return open ? 0 : height + edgeMargin + 8;
                        }
                        Behavior on y {
                            NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                        border.width: 1
                        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)
                        clip: true

                        ColumnLayout {
                            id: content
                            width: root.cardW
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.bottomMargin: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: "LocalSend"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    color: Colors.md3.on_surface
                                }

                                Md3Switch {
                                    checked: Config.localsend.enabled
                                    onToggled: v => LocalSendService.setEnabled(v)
                                }

                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: settingsMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "settings"
                                        iconSize: 18
                                        color: Colors.md3.on_surface_variant
                                    }
                                    MouseArea {
                                        id: settingsMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "system"]);
                                            root.close();
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: root.showIncoming
                                spacing: 0

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.margins: 16
                                    Layout.topMargin: 2
                                    radius: 16
                                    color: Colors.md3.tertiary_container
                                    implicitHeight: incomingCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: incomingCol
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            LsAvatar {
                                                deviceType: LocalSendService.pendingIncoming?.deviceType ?? ""
                                                bg: Qt.alpha(Colors.md3.on_tertiary_container, 0.14)
                                                fg: Colors.md3.on_tertiary_container
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: LocalSendService.pendingIncoming?.from ?? "A device"
                                                    font.family: Config.fontFamily
                                                    font.pixelSize: 13
                                                    font.weight: Font.Medium
                                                    color: Colors.md3.on_tertiary_container
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: {
                                                        const inc = LocalSendService.pendingIncoming;
                                                        const n = inc?.fileCount ?? (inc?.files?.length ?? 0);
                                                        const bytes = inc?.totalBytes ?? 0;
                                                        return "wants to send " + root.plural(n, "file") + (bytes ? " · " + root.humanSize(bytes) : "");
                                                    }
                                                    font.family: Config.fontFamily
                                                    font.pixelSize: 11
                                                    color: Colors.md3.on_tertiary_container
                                                    opacity: 0.75
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            id: incomingFilesCol
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 46
                                            spacing: 4

                                            readonly property var allFiles: LocalSendService.pendingIncoming?.files ?? []
                                            readonly property int maxShown: 5

                                            Repeater {
                                                model: incomingFilesCol.allFiles.slice(0, incomingFilesCol.maxShown)
                                                delegate: RowLayout {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.fileName ?? modelData.name ?? "file"
                                                        font.family: Config.fontFamily
                                                        font.pixelSize: 11
                                                        opacity: 0.85
                                                        color: Colors.md3.on_tertiary_container
                                                        elide: Text.ElideMiddle
                                                    }
                                                    Text {
                                                        text: root.humanSize(modelData.size ?? 0)
                                                        font.family: Config.fontMonospace
                                                        font.pixelSize: 11
                                                        opacity: 0.85
                                                        color: Colors.md3.on_tertiary_container
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: incomingFilesCol.allFiles.length > incomingFilesCol.maxShown
                                                text: "+ " + root.plural(incomingFilesCol.allFiles.length - incomingFilesCol.maxShown, "more file")
                                                font.family: Config.fontFamily
                                                font.pixelSize: 11
                                                opacity: 0.7
                                                color: Colors.md3.on_tertiary_container
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            spacing: 8
                                            Item { Layout.fillWidth: true }

                                            LsTextButton {
                                                text: "decline"
                                                textColor: Colors.md3.on_tertiary_container
                                                onClicked: LocalSendService.confirmReceive(LocalSendService.pendingIncoming?.sessionId ?? "", false)
                                            }
                                            LsFilledButton {
                                                text: "accept"
                                                bg: Colors.md3.tertiary
                                                fg: Colors.md3.on_tertiary
                                                onClicked: LocalSendService.confirmReceive(LocalSendService.pendingIncoming?.sessionId ?? "", true)
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 2
                                visible: root.showError
                                radius: 16
                                color: Colors.md3.error_container
                                implicitHeight: errorCol.implicitHeight + 28

                                ColumnLayout {
                                    id: errorCol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        LsAvatar {
                                            Layout.alignment: Qt.AlignTop
                                            deviceType: LocalSendService.lastResult?.deviceType ?? ""
                                            bg: Qt.alpha(Colors.md3.on_error_container, 0.14)
                                            fg: Colors.md3.on_error_container
                                            badge: "close"
                                            badgeBg: Colors.md3.error
                                            badgeFg: Colors.md3.on_error
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: LocalSendService.resultTitle(LocalSendService.lastResult) || "Transfer failed"
                                                font.family: Config.fontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: Colors.md3.on_error_container
                                                wrapMode: Text.WordWrap
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                visible: text.length > 0
                                                text: LocalSendService.resultDetail(LocalSendService.lastResult)
                                                font.family: Config.fontFamily
                                                font.pixelSize: 12
                                                opacity: 0.82
                                                color: Colors.md3.on_error_container
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Item { Layout.fillWidth: true }
                                        LsTextButton {
                                            text: "dismiss"
                                            textColor: Colors.md3.on_error_container
                                            onClicked: LocalSendService.dismissResult()
                                        }
                                        LsFilledButton {
                                            visible: LocalSendService.canRetry
                                            text: "retry"
                                            icon: "restart"
                                            bg: Colors.md3.error
                                            fg: "#690005"
                                            onClicked: LocalSendService.retryLastSend()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 2
                                visible: root.showWaiting
                                radius: 16
                                color: Colors.md3.secondary_container
                                implicitHeight: waitRow.implicitHeight + 24

                                readonly property var waitInfo: LocalSendService.activeTransfer ?? LocalSendService.pendingSend
                                readonly property bool inbound: LocalSendService.activeTransfer?.direction === "recv"

                                RowLayout {
                                    id: waitRow
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
                                    spacing: 12

                                    LsAvatar {
                                        deviceType: parent.parent.waitInfo?.deviceType ?? ""
                                        bg: Qt.alpha(Colors.md3.on_secondary_container, 0.14)
                                        fg: Colors.md3.on_secondary_container
                                        pulsing: root.showWaiting
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: {
                                                const w = waitRow.parent.waitInfo;
                                                return w?.peer ?? w?.targetName ?? "device";
                                            }
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_secondary_container
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: {
                                                const w = waitRow.parent.waitInfo;
                                                if (!w)
                                                    return "";
                                                const verb = waitRow.parent.inbound ? "waiting for files" : "waiting to accept";
                                                const n = w.total ?? w.fileCount ?? 0;
                                                const bytes = w.bytesTotal ?? w.totalBytes ?? 0;
                                                return verb + " · " + root.plural(n, "file") + (bytes ? " · " + root.humanSize(bytes) : "");
                                            }
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            color: Colors.md3.on_secondary_container
                                            opacity: 0.75
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: cancelWaitMa.containsMouse ? Qt.alpha(Colors.md3.on_secondary_container, 0.18) : Qt.alpha(Colors.md3.on_secondary_container, 0.1)
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        MaterialIcon { anchors.centerIn: parent; name: "close"; iconSize: 14; color: Colors.md3.on_secondary_container }
                                        MouseArea {
                                            id: cancelWaitMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: LocalSendService.cancelAll()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 2
                                visible: root.showTransfer
                                radius: 16
                                color: Colors.md3.surface_container_high
                                implicitHeight: sendCol.implicitHeight + 28

                                ColumnLayout {
                                    id: sendCol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                                    spacing: 8

                                    readonly property bool receiving: LocalSendService.receiving

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        LsAvatar {
                                            deviceType: LocalSendService.activeTransfer?.deviceType ?? ""
                                            bg: Colors.md3.surface_container_highest
                                            fg: Colors.md3.primary
                                            spinning: root.showTransfer
                                            badge: sendCol.receiving ? "arrow-downward" : "arrow-upward"
                                            badgeBg: Colors.md3.primary
                                            badgeFg: Colors.md3.on_primary
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: LocalSendService.activeTransfer?.fileName ?? (sendCol.receiving ? "Receiving…" : "Sending…")
                                                font.family: Config.fontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: Colors.md3.on_surface
                                                elide: Text.ElideMiddle
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: {
                                                    const t = LocalSendService.activeTransfer;
                                                    if (!t)
                                                        return "";
                                                    const where = (sendCol.receiving ? "from " : "to ") + (t.peer ?? "device");
                                                    const count = (t.total ?? 0) > 1 ? " · " + (Math.min((t.index ?? 0) + 1, t.total)) + " of " + t.total : "";
                                                    const bytes = (t.bytesTotal ?? 0) > 0 ? " · " + root.humanSize(t.bytesDone ?? 0) + " / " + root.humanSize(t.bytesTotal) : "";
                                                    return where + count + bytes;
                                                }
                                                font.family: Config.fontFamily
                                                font.pixelSize: 11
                                                color: Colors.md3.on_surface_variant
                                                elide: Text.ElideRight
                                            }
                                        }
                                        Rectangle {
                                            width: 28; height: 28; radius: 14
                                            color: cancelOneMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            MaterialIcon { anchors.centerIn: parent; name: "close"; iconSize: 14; color: Colors.md3.on_surface_variant }
                                            MouseArea {
                                                id: cancelOneMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: LocalSendService.cancelAll()
                                            }
                                        }
                                    }

                                    Item {
                                        id: progressTrack
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        implicitHeight: 6

                                        readonly property real gap: 2

                                        Rectangle {
                                            id: progressFill
                                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                            width: Math.max(0, (progressTrack.width - progressTrack.gap * 2) * LocalSendService.transferProgress)
                                            height: parent.height
                                            radius: height / 2
                                            color: Colors.md3.primary
                                            Behavior on width { NumberAnimation { duration: 200 } }
                                        }

                                        Rectangle {
                                            anchors {
                                                left: progressFill.right
                                                leftMargin: progressTrack.gap * 2
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                            }
                                            height: parent.height
                                            radius: height / 2
                                            color: Colors.md3.surface_variant
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                Layout.topMargin: 2
                                Layout.bottomMargin: 10
                                visible: root.showDone
                                radius: 16
                                color: LocalSendService.resultIsOk ? Colors.md3.primary_container : Colors.md3.surface_container_high
                                implicitHeight: doneRow.implicitHeight + 24

                                readonly property color fgColor: LocalSendService.resultIsOk ? Colors.md3.on_primary_container : Colors.md3.on_surface

                                RowLayout {
                                    id: doneRow
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
                                    spacing: 10
                                    LsAvatar {
                                        deviceType: LocalSendService.lastResult?.deviceType ?? ""
                                        bg: Qt.alpha(doneRow.parent.fgColor, 0.14)
                                        fg: doneRow.parent.fgColor
                                        badge: LocalSendService.resultIsOk ? "check" : "close"
                                        badgeBg: LocalSendService.resultIsOk ? Colors.md3.primary : Colors.md3.outline
                                        badgeFg: LocalSendService.resultIsOk ? Colors.md3.on_primary : Colors.md3.surface
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: LocalSendService.resultTitle(LocalSendService.lastResult)
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: doneRow.parent.fgColor
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: {
                                                const r = LocalSendService.lastResult;
                                                if (!r)
                                                    return "";
                                                if (r.kind === "sent")
                                                    return "Sent " + root.plural(r.count ?? 0, "file");
                                                if (r.kind === "received")
                                                    return "Received " + root.plural(r.count ?? 0, "file");
                                                return LocalSendService.resultDetail(r);
                                            }
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            color: doneRow.parent.fgColor
                                            opacity: 0.75
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: dismissDoneMa.containsMouse ? Qt.alpha(doneRow.parent.fgColor, 0.14) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        MaterialIcon { anchors.centerIn: parent; name: "close"; iconSize: 14; color: doneRow.parent.fgColor }
                                        MouseArea {
                                            id: dismissDoneMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: LocalSendService.dismissResult()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                Layout.topMargin: 2
                                Layout.bottomMargin: 16
                                visible: root.showPin
                                radius: 16
                                color: Colors.md3.tertiary_container
                                implicitHeight: pinCol.implicitHeight + 28

                                onVisibleChanged: {
                                    if (visible && popup.isOwnScreen) {
                                        pinField.text = "";
                                        pinField.forceActiveFocus();
                                    }
                                }

                                ColumnLayout {
                                    id: pinCol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                                    spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        LsAvatar {
                                            deviceType: LocalSendService.pinRequest?.deviceType ?? ""
                                            bg: Qt.alpha(Colors.md3.on_tertiary_container, 0.14)
                                            fg: Colors.md3.on_tertiary_container
                                            badge: "password-2"
                                            badgeBg: Colors.md3.tertiary
                                            badgeFg: Colors.md3.on_tertiary
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: {
                                                const r = LocalSendService.pinRequest;
                                                const who = r?.targetName ?? "The recipient";
                                                return r?.badPin ? "Wrong PIN — try again" : who + " requires a PIN";
                                            }
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_tertiary_container
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 46
                                        implicitHeight: 34
                                        radius: 10
                                        color: Colors.md3.surface_container_high

                                        TextInput {
                                            id: pinField
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: Config.fontMonospace
                                            font.pixelSize: 14
                                            color: Colors.md3.on_surface
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            onAccepted: LocalSendService.submitPin(text)
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Item { Layout.fillWidth: true }
                                        LsTextButton {
                                            text: "cancel"
                                            textColor: Colors.md3.on_tertiary_container
                                            onClicked: LocalSendService.cancelPinRequest()
                                        }
                                        LsFilledButton {
                                            text: "send"
                                            bg: Colors.md3.tertiary
                                            fg: Colors.md3.on_tertiary
                                            onClicked: LocalSendService.submitPin(pinField.text)
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: root.showPicker
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 16
                                    Layout.topMargin: 6
                                    Layout.bottomMargin: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.attached.length > 0 ? "attached · " + root.plural(root.attached.length, "file") + " · " + root.humanSize(root.attached.reduce((a, f) => a + (f.size ?? 0), 0)) : "attached"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_surface_variant
                                    }

                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        color: openFolderMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "folder"
                                            iconSize: 14
                                            color: Colors.md3.on_surface_variant
                                        }
                                        MouseArea {
                                            id: openFolderMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const dir = LocalSendService.localDownloadDir || (Quickshell.env("HOME") + "/Downloads/LocalSend");
                                                Qt.openUrlExternally("file://" + dir);
                                                root.close();
                                            }
                                        }
                                    }

                                    LsTextButton {
                                        text: root.attached.length > 0 ? "clear" : "choose files"
                                        textColor: Colors.md3.primary
                                        onClicked: {
                                            if (root.attached.length > 0) {
                                                LocalSendService.clearAttached();
                                            } else {
                                                filePicker.open();
                                                root.close();
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.bottomMargin: 14
                                    visible: root.attached.length === 0
                                    radius: 16
                                    border.width: 1.5
                                    border.color: Colors.md3.outline_variant
                                    color: dropMa.containsMouse ? Qt.alpha(Colors.md3.primary, 0.06) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    implicitHeight: 60

                                    Text {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Drop files here or click to choose"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                        color: Colors.md3.on_surface_variant
                                    }

                                    MouseArea {
                                        id: dropMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            filePicker.open();
                                            root.close();
                                        }
                                    }
                                }

                                Flickable {
                                    id: chipsFlick
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.bottomMargin: 14
                                    visible: root.attached.length > 0
                                    implicitHeight: Math.min(chipFlow.implicitHeight, 74)
                                    contentHeight: chipFlow.implicitHeight
                                    contentWidth: width
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickableDirection: Flickable.VerticalFlick

                                    Flow {
                                        id: chipFlow
                                        width: chipsFlick.width
                                        spacing: 8
                                        topPadding: 6
                                        rightPadding: 6

                                        Repeater {
                                            model: root.attached
                                            delegate: LsChip {
                                                required property var modelData
                                                fileName: modelData.name ?? ""
                                                fileSize: modelData.size ?? 0
                                                onRemove: LocalSendService.removeAttached(modelData.path)
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: !Config.localsend.enabled
                                Layout.topMargin: 4
                                Layout.bottomMargin: 18
                                spacing: 10

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 44; height: 44
                                    MaterialShape {
                                        anchors.fill: parent
                                        name: "cookie9"
                                        shapeSize: 44
                                        color: Colors.md3.surface_container_high
                                    }
                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "wifi-tethering"
                                        iconSize: 18
                                        color: Colors.md3.on_surface_variant
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "LocalSend is off"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 13
                                    color: Colors.md3.on_surface
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 30
                                    Layout.rightMargin: 30
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Flip the switch above to start the server and become visible to nearby devices."
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Colors.md3.on_surface_variant
                                    wrapMode: Text.WordWrap
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: root.showDevices
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 16
                                    Layout.bottomMargin: 8
                                    spacing: 8

                                    MaterialIcon {
                                        name: LocalSendService.reachable ? "check-circle" : "error"
                                        iconSize: 14
                                        color: LocalSendService.reachable ? Colors.md3.primary : Colors.md3.outline
                                    }
                                    Text {
                                        text: "Nearby devices (" + root.devices.length + ")"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_surface_variant
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: (Config.localsend.alias ?? "").trim() || LocalSendService.localAlias || "this device"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_surface_variant
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 140
                                    }

                                    Rectangle {
                                        width: 32; height: 26; radius: 13
                                        color: dtMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: LocalSendService.deviceTypeIcon(Config.localsend.deviceType ?? "desktop")
                                            iconSize: 15
                                            color: Colors.md3.on_surface_variant
                                        }
                                        MouseArea {
                                            id: dtMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: LocalSendService.cycleDeviceType()
                                        }
                                    }
                                }

                                Repeater {
                                    model: root.devices
                                    delegate: LsDeviceRow {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        deviceName: modelData.alias ?? modelData.name ?? "Unknown device"
                                        deviceType: modelData.deviceType ?? modelData.type ?? ""
                                        deviceMeta: modelData.ip ?? modelData.address ?? ""
                                        armed: root.attached.length > 0 && !LocalSendService.activeTransfer && !LocalSendService.pendingSend
                                        onActivated: LocalSendService.sendFiles(modelData, root.attached.map(f => f.path))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: root.devices.length === 0
                                    Layout.topMargin: 12
                                    Layout.bottomMargin: 18
                                    spacing: 10

                                    Item {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 44; height: 44
                                        MaterialShape {
                                            anchors.fill: parent
                                            name: "cookie9"
                                            shapeSize: 44
                                            color: Colors.md3.surface_container_high
                                        }
                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "question-mark"
                                            iconSize: 18
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "No devices nearby"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        color: Colors.md3.on_surface
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 30
                                        Layout.rightMargin: 30
                                        horizontalAlignment: Text.AlignHCenter
                                        text: !LocalSendService.reachable ? "The LocalSend server isn't running yet." : (!LocalSendService.multicastOk ? "Multicast is unavailable on this network, so nearby devices can't be discovered automatically." : "Make sure LocalSend is open on the other device and both are on the same network.")
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        color: Colors.md3.on_surface_variant
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 12
                                    Layout.topMargin: 4
                                    Layout.bottomMargin: 10
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: LocalSendService.localIp ? LocalSendService.localIp + ":" + Config.localsend.port : "finding address…"
                                        font.family: Config.fontMonospace
                                        font.pixelSize: 10
                                        color: Colors.md3.on_surface_variant
                                        elide: Text.ElideRight
                                    }
                                    LsTextButton {
                                        text: "scan"
                                        icon: "restart"
                                        textColor: Colors.md3.primary
                                        onClicked: LocalSendService.scanNow()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function plural(n, noun) {
        return n + " " + noun + (n === 1 ? "" : "s");
    }

    function fileIconFor(name) {
        const ext = (name.split(".").pop() ?? "").toLowerCase();
        if (["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "tiff", "ico"].includes(ext))
            return "image";
        if (["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(ext))
            return "video";
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"].includes(ext))
            return "queue-music";
        if (["sh", "py", "js", "ts", "qml", "c", "cpp", "h", "rs", "go", "json", "yaml", "yml", "toml", "html", "css"].includes(ext))
            return "terminal";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext))
            return "folder-zip";
        if (["pdf", "txt", "md", "doc", "docx", "odt", "rtf"].includes(ext))
            return "description";
        return "question-mark";
    }

    function humanSize(bytes) {
        if (!bytes || bytes <= 0)
            return "0 B";
        const units = ["B", "KB", "MB", "GB"];
        let i = 0;
        let v = bytes;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    component LsTextButton: Rectangle {
        id: btn
        property string text: ""
        property string icon: ""
        property color textColor: Colors.md3.on_surface
        signal clicked

        implicitWidth: btnRow.implicitWidth + 16
        implicitHeight: 26
        radius: 13
        color: btnMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 5
            MaterialIcon {
                visible: btn.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                name: btn.icon
                iconSize: 13
                color: btn.textColor
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.text
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: btn.textColor
            }
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component LsFilledButton: Rectangle {
        id: fbtn
        property string text: ""
        property string icon: ""
        property color bg: Colors.md3.primary
        property color fg: Colors.md3.on_primary
        signal clicked

        implicitWidth: fbtnRow.implicitWidth + 26
        implicitHeight: 30
        radius: 15
        color: fbtnMa.containsMouse ? Qt.lighter(fbtn.bg, 1.08) : fbtn.bg

        Row {
            id: fbtnRow
            anchors.centerIn: parent
            spacing: 6
            MaterialIcon {
                visible: fbtn.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                name: fbtn.icon
                iconSize: 13
                color: fbtn.fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: fbtn.text
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: fbtn.fg
            }
        }

        MouseArea {
            id: fbtnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fbtn.clicked()
        }
    }

    component LsAvatar: Item {
        id: avatar
        property string deviceType: ""
        property color bg: Colors.md3.surface_container_high
        property color fg: Colors.md3.on_surface_variant
        property real size: 36
        property bool pulsing: false
        property bool spinning: false
        property string badge: ""
        property color badgeBg: Colors.md3.primary
        property color badgeFg: Colors.md3.on_primary

        implicitWidth: size
        implicitHeight: size

        onPulsingChanged: if (!pulsing)
            avatarShape.opacity = 1
        onSpinningChanged: if (!spinning)
            avatarShape.rotation = 0

        MaterialShape {
            id: avatarShape
            anchors.fill: parent
            name: "cookie9"
            shapeSize: avatar.size
            color: avatar.bg

            RotationAnimation on rotation {
                running: avatar.spinning
                from: 0
                to: 360
                duration: 20000
                loops: Animation.Infinite
            }
        }
        MaterialIcon {
            anchors.centerIn: parent
            name: LocalSendService.deviceTypeIcon(avatar.deviceType)
            iconSize: Math.round(avatar.size * 0.45)
            color: avatar.fg
        }
        Rectangle {
            visible: avatar.badge.length > 0
            width: Math.round(avatar.size * 0.44); height: width; radius: width / 2
            anchors { right: parent.right; bottom: parent.bottom }
            color: avatar.badgeBg
            MaterialIcon {
                anchors.centerIn: parent
                name: avatar.badge
                iconSize: Math.round(parent.width * 0.62)
                color: avatar.badgeFg
            }
        }
    }

    component LsChip: Rectangle {
        id: chip
        property string fileName: ""
        property real fileSize: 0
        signal remove

        implicitWidth: chipRow.implicitWidth + 20
        height: 34
        radius: 10
        color: chipMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
        Behavior on color { ColorAnimation { duration: 100 } }

        MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    chip.remove();
            }
        }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 7

            Rectangle {
                id: iconSlot
                width: 22; height: 22; radius: 6
                color: chipMa.containsMouse ? Colors.md3.error_container : Colors.md3.primary_container
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 100 } }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: chipMa.containsMouse ? "close" : root.fileIconFor(chip.fileName)
                    iconSize: 13
                    color: chipMa.containsMouse ? Colors.md3.on_error_container : Colors.md3.on_primary_container
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chip.remove()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: chipName
                    text: chip.fileName
                    width: Math.min(96, implicitWidth)
                    elide: Text.ElideRight
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.on_surface
                }
                Text {
                    text: root.humanSize(chip.fileSize)
                    font.family: Config.fontMonospace
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }

    component LsDeviceRow: Item {
        id: devRow
        property string deviceName: ""
        property string deviceType: "desktop"
        property string deviceMeta: ""
        property bool armed: false
        signal activated

        implicitHeight: 52

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 16
            color: devRow.armed && devMa.containsMouse ? Colors.md3.secondary_container : Qt.alpha(Colors.md3.secondary_container, 0)
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 14

            Rectangle {
                width: 40; height: 40; radius: 12
                color: Colors.md3.secondary_container
                MaterialIcon {
                    anchors.centerIn: parent
                    name: LocalSendService.deviceTypeIcon(devRow.deviceType)
                    iconSize: 20
                    color: Colors.md3.on_secondary_container
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: devRow.deviceName
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: devRow.armed && devMa.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                    elide: Text.ElideRight
                }
                Text {
                    text: (devRow.deviceType || "unknown") + (devRow.deviceMeta ? " · " + devRow.deviceMeta : "")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: devRow.armed && devMa.containsMouse ? Qt.alpha(Colors.md3.on_secondary_container, 0.75) : Colors.md3.on_surface_variant
                }
            }

            MaterialIcon {
                Layout.rightMargin: 4
                name: "arrow-forward"
                iconSize: 16
                color: Colors.md3.on_secondary_container
                opacity: devRow.armed && devMa.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 130 } }
            }
        }

        MouseArea {
            id: devMa
            anchors.fill: parent
            enabled: devRow.armed
            hoverEnabled: devRow.armed
            cursorShape: devRow.armed ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: devRow.activated()
        }
    }
}
