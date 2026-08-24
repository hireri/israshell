import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.icons
import qs.services
import Quickshell.Widgets

Rectangle {
    id: root

    required property var panelWindow
    property var controllerRegistry: null

    readonly property bool wallpaperOpen: WallpaperService.isOpen && WallpaperService.openWindow === root.panelWindow

    readonly property bool isOpen: false

    function getScript(path) {
        if (!path || path === "")
            return "";
        return path.replace(/^~/, Quickshell.env("HOME"));
    }

    function isEnabled(name) {
        if (name === "colorpicker" && CompositorService.backendName !== "hyprland")
            return false;
        return !Config.screencap.blacklist.includes(name);
    }

    readonly property var songrecEnv: ({
            NOTIFY_FIND_ON_GOOGLE_ACTION: Localization.t("songrecScript.find_on_google_action"),
            NOTIFY_NO_MATCH_TITLE: Localization.t("songrecScript.no_match_title"),
            NOTIFY_NO_MATCH_FILE_BODY: Localization.t("songrecScript.no_match_file_body"),
            NOTIFY_NO_MATCH_LIVE_BODY: Localization.t("songrecScript.no_match_live_body")
        })

    function componentFor(type) {
        switch (type) {
        case "wallpaper":
            return wallpaperComp;
        case "screenshot":
            return screenshotComp;
        case "cts":
            return ctsComp;
        case "ocr":
            return ocrComp;
        case "colorpicker":
            return colorpickerComp;
        case "localsend":
            return localsendComp;
        case "songrec":
            return songrecComp;
        case "record":
            return recordComp;
        default:
            return null;
        }
    }

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else { 
            Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        }
    }   

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    radius: 20
    implicitHeight: 32
    implicitWidth: screencapList.contentWidth + leftPad + rightPad

    readonly property int leftPad: 3
    readonly property int rightPad: 3

    Process {
        id: recordScript
        command: ["sh", "-c", "qs -c isra ipc call screenshot record"]
    }
    Process {
        id: screenshotScript
        command: ["sh", "-c", "qs -c isra ipc call screenshot activate"]
    }
    Process {
        id: ctsScript
        command: ["sh", "-c", "qs -c isra ipc call screenshot cts"]
    }
    Process {
        id: ocrScript
        command: ["sh", "-c", "qs -c isra ipc call screenshot ocr"]
    }
    Process {
        id: songrecScript
        command: ["sh", "-c", getScript(Config.screencap.songrecPath)]
        environment: root.songrecEnv
    }

    Process {
        id: colorPickerScript
        command: ["hyprpicker", "--autocopy"]
    }

    BarTooltip {
        id: tooltipWindow
        panelWindow: root.panelWindow
        yOffset: 4
    }

    Item {
        id: rowLayout
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        anchors.verticalCenter: parent.verticalCenter
        width: screencapList.contentWidth
        height: 32

        readonly property Item rowContainer: screencapList.contentItem

        property string draggingType: ""
        property int dragSourceIndex: -1
        property real dragX: 0
        property real dragClickOffset: 0
        property bool isReleasing: false

        function commitOrder() {
            const newOrder = [];
            for (let i = 0; i < orderModel.count; i++)
                newOrder.push(orderModel.get(i).type);
            for (const t of Config.screencap.order)
                if (!newOrder.includes(t))
                    newOrder.push(t);
            Config.update({
                screencap: Object.assign({}, Config.screencap, {
                    order: newOrder
                })
            });
        }

        function rebuildModel() {
            if (rowLayout.draggingType !== "")
                return;
            const active = Config.screencap.order.filter(t => root.isEnabled(t) && root.componentFor(t));
            if (active.length === orderModel.count) {
                let same = true;
                for (let i = 0; i < active.length; i++) {
                    if (orderModel.get(i).type !== active[i]) {
                        same = false;
                        break;
                    }
                }
                if (same)
                    return;
            }
            orderModel.clear();
            for (const t of active)
                orderModel.append({
                    type: t
                });
        }

        function beginDrag(type, startX) {
            releaseTimer.stop();
            isReleasing = false;

            dragSourceIndex = -1;
            for (let i = 0; i < orderModel.count; i++) {
                if (orderModel.get(i).type === type) {
                    dragSourceIndex = i;
                    break;
                }
            }
            if (dragSourceIndex === -1)
                return;

            const item = screencapList.itemAtIndex(dragSourceIndex);
            dragClickOffset = startX - (item ? item.x : 0);
            dragX = startX;
            draggingType = type;
        }

        function updateDrag(type, sceneX) {
            if (draggingType !== type || isReleasing)
                return;

            const draggedItem = screencapList.itemAtIndex(dragSourceIndex);
            const draggedWidth = draggedItem ? draggedItem.width : 32;
            const maxX = Math.max(0, screencapList.contentWidth - draggedWidth);
            const clampedX = Math.max(0, Math.min(maxX, sceneX - dragClickOffset));
            dragX = clampedX + dragClickOffset;

            const pointerX = Math.max(0, Math.min(screencapList.contentWidth, sceneX));

            let targetIdx = dragSourceIndex;
            if (dragSourceIndex < orderModel.count - 1) {
                const rightItem = screencapList.itemAtIndex(dragSourceIndex + 1);
                if (rightItem && pointerX > rightItem.x + rightItem.width / 2)
                    targetIdx = dragSourceIndex + 1;
            }
            if (targetIdx === dragSourceIndex && dragSourceIndex > 0) {
                const leftItem = screencapList.itemAtIndex(dragSourceIndex - 1);
                if (leftItem && pointerX < leftItem.x + leftItem.width / 2)
                    targetIdx = dragSourceIndex - 1;
            }
            if (targetIdx !== dragSourceIndex) {
                orderModel.move(dragSourceIndex, targetIdx, 1);
                dragSourceIndex = targetIdx;
            }
        }

        function endDrag() {
            const type = draggingType;
            if (type !== "") {
                isReleasing = true;
                rowLayout.commitOrder();
                releaseTimer.start();
            } else {
                draggingType = "";
                dragSourceIndex = -1;
                isReleasing = false;
            }
        }

        Timer {
            id: releaseTimer
            interval: 220
            repeat: false
            onTriggered: {
                rowLayout.draggingType = "";
                rowLayout.dragSourceIndex = -1;
                rowLayout.isReleasing = false;
            }
        }

        ListModel {
            id: orderModel
        }

        Component.onCompleted: rebuildModel()

        Connections {
            target: Config
            function onScreencapChanged() {
                rowLayout.rebuildModel();
            }
        }

        ListView {
            id: screencapList
            anchors.fill: parent
            orientation: ListView.Horizontal
            interactive: false
            spacing: 4
            clip: false
            width: contentWidth
            model: orderModel

            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 0
                }
            }
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            moveDisplaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            delegate: Item {
                id: delegateRoot
                required property string type
                required property int index

                readonly property bool isDraggingSelf: rowLayout.draggingType === delegateRoot.type

                width: loader.item ? loader.item.width : 0
                height: 32
                z: isDraggingSelf ? 10 : 0
                scale: isDraggingSelf && !rowLayout.isReleasing ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Loader {
                    id: loader
                    x: delegateRoot.isDraggingSelf && !rowLayout.isReleasing ? (rowLayout.dragX - rowLayout.dragClickOffset) - delegateRoot.x : 0
                    sourceComponent: root.componentFor(delegateRoot.type)

                    Behavior on x {
                        enabled: !delegateRoot.isDraggingSelf || rowLayout.isReleasing
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                DragHandler {
                    id: dragHandler
                    target: null
                    yAxis.enabled: false
                    dragThreshold: 8

                    onActiveChanged: {
                        if (dragHandler.active) {
                            const scenePos = delegateRoot.mapToItem(rowLayout.rowContainer, dragHandler.centroid.position.x, 0);
                            rowLayout.beginDrag(delegateRoot.type, scenePos.x);
                        } else {
                            rowLayout.endDrag();
                        }
                    }

                    onCentroidChanged: {
                        if (!dragHandler.active)
                            return;
                        const scenePos = delegateRoot.mapToItem(rowLayout.rowContainer, dragHandler.centroid.position.x, 0);
                        rowLayout.updateDrag(delegateRoot.type, scenePos.x);
                    }
                }
            }
        }
    }

    Component {
        id: wallpaperComp
        Item {
            width: 32
            height: 32

            ToolButton {
                anchors.centerIn: parent
                height: 26
                tooltip: Localization.t("backgroundPage.wallpaper")
                active: root.wallpaperOpen
                opacity: WallpaperService.applying ? 0.4 : 1.0
                onClicked: WallpaperService.toggleFor(root.panelWindow)
                MaterialIcon {
                    name: "wallpapers"
                    iconSize: 18
                    anchors.centerIn: parent
                    color: root.wallpaperOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }
    }

    Component {
        id: screenshotComp
        ToolButton {
            tooltip: Localization.t("qsTileService.screenshot")
            onClicked: screenshotScript.startDetached()
            MaterialIcon {
                name: "screenshot"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }
    }

    Component {
        id: ctsComp
        ToolButton {
            tooltip: Localization.t("qsTileService.circle_to_search")
            onClicked: ctsScript.startDetached()
            MaterialIcon {
                name: "image-search"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }
    }

    Component {
        id: ocrComp
        ToolButton {
            tooltip: Localization.t("qsTileService.ocr_text")
            onClicked: ocrScript.startDetached()
            MaterialIcon {
                name: "ocr"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }
    }

    Component {
        id: colorpickerComp
        ToolButton {
            tooltip: Localization.t("qsTileService.color_picker")
            onClicked: colorPickerScript.startDetached()
            MaterialIcon {
                name: "colorize"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
                transitionType: "none"
            }
        }
    }

    Component {
        id: localsendComp
        Item {
            id: lsItem
            width: lsBg.width
            height: 32

            readonly property string lsState: lsDrop.containsDrag ? "drag" : LocalSendService.pillState

            readonly property string lsLabel: {
                switch (lsState) {
                case "drag":
                    return Localization.t("screencapControls.drop_to_send");
                case "staged":
                    return String(LocalSendService.attachedFiles.length);
                case "sending":
                    return Math.round(100 * LocalSendService.transferProgress) + "%";
                case "waiting":
                    return Localization.t("screencapControls.waiting");
                case "incoming":
                    return Localization.t("screencapControls.incoming");
                case "pin":
                    return Localization.t("passwordWidget.pin");
                case "done":
                    switch (LocalSendService.lastResult?.kind) {
                    case "sent":
                        return Localization.t("screencapControls.sent");
                    case "received":
                        return Localization.t("screencapControls.received");
                    case "declined":
                        return Localization.t("screencapControls.declined");
                    case "recv_timeout":
                        return Localization.t("screencapControls.expired");
                    default:
                        return Localization.t("localSend.cancelled");
                    }
                case "error":
                    return Localization.t("screencapControls.failed");
                default:
                    return "";
                }
            }
            readonly property bool lsExpanded: lsLabel.length > 0

            readonly property color lsFg: {
                if (lsPopover.isOpen)
                    return Colors.md3.on_secondary_container;
                switch (lsState) {
                case "drag":
                case "staged":
                case "sending":
                case "waiting":
                    return Colors.md3.primary;
                case "done":
                    return LocalSendService.resultIsOk ? Colors.md3.primary : Colors.md3.on_surface_variant;
                case "incoming":
                case "pin":
                    return Colors.md3.tertiary;
                case "error":
                    return Colors.md3.error;
                default:
                    return Colors.md3.on_surface;
                }
            }

            LocalSendPopover {
                id: lsPopover
                panelWindow: root.panelWindow
                widgetItem: lsItem
                controllerRegistry: root.controllerRegistry
            }

            Connections {
                target: LocalSendService
                function onPendingIncomingChanged() {
                    if (!isEnabled("localsend") || !LocalSendService.pendingIncoming || lsPopover.isOpen)
                        return;
                    const focused = CompositorService.focusedMonitor?.name ?? "";
                    if (focused && root.panelWindow.screen?.name !== focused)
                        return;
                    lsPopover.open();
                }
            }

            Rectangle {
                id: lsBg
                anchors.verticalCenter: parent.verticalCenter
                width: lsItem.lsExpanded ? 5 + 18 + 6 + lsLabelText.implicitWidth + 11 : 32
                height: 26
                radius: 16
                color: {
                    if (lsPopover.isOpen)
                        return Colors.md3.secondary_container;
                    switch (lsItem.lsState) {
                    case "drag":
                    case "staged":
                    case "sending":
                    case "waiting":
                        return Qt.alpha(Colors.md3.primary, 0.15);
                    case "done":
                        return Qt.alpha(LocalSendService.resultIsOk ? Colors.md3.primary : Colors.md3.on_surface_variant, 0.15);
                    case "incoming":
                    case "pin":
                        return Qt.alpha(Colors.md3.tertiary, 0.2);
                    case "error":
                        return Qt.alpha(Colors.md3.error, 0.15);
                    default:
                        return "transparent";
                    }
                }
                border.width: 1
                border.color: lsItem.lsState === "drag" ? Colors.md3.primary : lsBg.color
                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                MaterialIcon {
                    id: lsIcon
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: lsItem.lsExpanded ? 5 : 7
                    visible: lsItem.lsState !== "sending"
                    transitionType: "none"
                    name: {
                        switch (lsItem.lsState) {
                        case "drag":
                            return "swap-horiz";
                        case "incoming":
                            return "downloading";
                        case "sending":
                        case "waiting":
                            return LocalSendService.receiving ? "downloading" : "uploading";
                        case "staged":
                            return "upload-file";
                        case "pin":
                            return "password-2";
                        case "done":
                            return LocalSendService.resultIsOk ? "check" : "close";
                        case "error":
                            return "sentiment-frustrated";
                        default:
                            return Config.localsend.enabled ? "wifi-tethering" : "wifi-tethering-off";
                        }
                    }
                    iconSize: 18
                    color: lsItem.lsFg
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                LoadingSpinner {
                    id: lsSpinner
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    visible: lsItem.lsState === "sending"
                    size: 16
                    color: lsItem.lsFg
                }

                Text {
                    id: lsLabelText
                    anchors.left: parent.left
                    anchors.leftMargin: 5 + 18 + 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: lsItem.lsLabel
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: lsItem.lsFg
                    opacity: lsItem.lsExpanded ? 1 : 0
                    font.features: {
                        "tnum": 1
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            MouseArea {
                id: lsMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: lsPopover.isOpen ? lsPopover.close() : lsPopover.open()
                onEntered: {
                    var yPos = Config.bar.position === 1 ? 0 : height;
                    tooltipWindow.targetPos = mapToGlobal(width / 2, yPos);
                    tooltipWindow.tipTitle = Localization.t("qsTileService.localsend");
                    tooltipWindow.open = true;
                }
                onExited: tooltipWindow.open = false
            }

            DropArea {
                id: lsDrop
                anchors.fill: parent
                onDropped: drop => {
                    if (!drop.urls || drop.urls.length === 0)
                        return;
                    LocalSendService.attachFilesFromUrls(drop.urls);
                    drop.accept();
                }
            }
        }
    }

    Component {
        id: songrecComp
        Item {
            id: srItem
            width: songrecBg.width
            height: 32

            property bool fileRecognizing: false
            readonly property bool dragActive: srDrop.containsDrag
            readonly property bool fileActive: fileRecognizing || dragActive

            function recognizeFile(path) {
                if (srItem.fileRecognizing)
                    return;
                srItem.fileRecognizing = true;
                songrecFileScript.command = ["sh", getScript(Config.screencap.songrecPath), path];
                songrecFileScript.running = true;
            }

            Process {
                id: songrecFileScript
                environment: root.songrecEnv
                onExited: srItem.fileRecognizing = false
            }

            Rectangle {
                id: songrecBg
                anchors.verticalCenter: parent.verticalCenter
                width: (ScreencapService.isRecognizing || srItem.fileActive) ? 38 : 32
                height: 26
                radius: 16
                color: {
                    if (srItem.fileActive)
                        return Qt.alpha(Colors.md3.tertiary, 0.15);
                    if (ScreencapService.isRecognizing)
                        return Qt.alpha(Colors.md3.primary, 0.15);
                    return songrecHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent";
                }
                border.width: srItem.dragActive ? 1 : 0
                border.color: Colors.md3.tertiary

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            MaterialIcon {
                name: "songrec"
                iconSize: 18
                anchors.centerIn: parent
                color: srItem.fileActive ? Colors.md3.tertiary : (ScreencapService.isRecognizing ? Colors.md3.primary : Colors.md3.on_surface)
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            HoverHandler {
                id: songrecHover
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (srItem.fileRecognizing) {
                        songrecFileScript.running = false;
                        srItem.fileRecognizing = false;
                        return;
                    }
                    ScreencapService.toggleRecognitionOptimistic();
                    songrecScript.startDetached();
                }
                onEntered: {
                    var yPos = Config.bar.position === 1 ? 0 : height;
                    tooltipWindow.targetPos = mapToGlobal(width / 2, yPos);
                    tooltipWindow.tipTitle = srItem.fileRecognizing ? Localization.t("screencapControls.recognizing_file") : (ScreencapService.isRecognizing ? Localization.t("screencapControls.stop_recognizing") : Localization.t("barPage.recognize_music"));
                    tooltipWindow.open = true;
                }
                onExited: tooltipWindow.open = false
            }

            DropArea {
                id: srDrop
                anchors.fill: parent
                enabled: !ScreencapService.isRecognizing && !srItem.fileRecognizing
                onDropped: drop => {
                    if (!drop.urls || drop.urls.length === 0)
                        return;
                    const path = decodeURIComponent(drop.urls[0].toString().replace(/^file:\/\//, ""));
                    srItem.recognizeFile(path);
                    drop.accept();
                }
            }
        }
    }

    Component {
        id: recordComp
        Item {
            height: 32
            width: recordBg.width

            ClippingRectangle {
                id: recordBg
                anchors.verticalCenter: parent.verticalCenter
                readonly property int textWidth: ScreencapService.recordingTime.length > 5 ? 57 : 38
                width: ScreencapService.isRecording ? 32 + 8 + textWidth : 32
                height: 26
                radius: 16
                color: ScreencapService.isRecording ? Qt.alpha(Colors.md3.error, 0.15) : (recordHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent")

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                MaterialIcon {
                    name: "record"
                    id: recIcon
                    iconSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: ScreencapService.isRecording ? 5 : 7
                    color: ScreencapService.isRecording ? Colors.md3.error : Colors.md3.on_surface
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                Text {
                    id: recordingText
                    anchors.left: recIcon.right
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: ScreencapService.recordingTime
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.error
                    opacity: ScreencapService.isRecording ? 1 : 0
                    font.features: {
                        "tnum": 1
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            HoverHandler {
                id: recordHover
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: recordScript.startDetached()
                onEntered: {
                    var yPos = Config.bar.position === 1 ? 0 : height;
                    tooltipWindow.targetPos = mapToGlobal(width / 2, yPos);
                    tooltipWindow.tipTitle = ScreencapService.isRecording ? Localization.t("screencapControls.stop_recording") : Localization.t("screencapControls.start_recording");
                    tooltipWindow.open = true;
                }
                onExited: tooltipWindow.open = false
            }
        }
    }

    component ToolButton: Rectangle {
        id: toolBtn
        property string tooltip
        property bool active: false
        signal clicked

        width: 32
        height: 32
        radius: 16
        color: active ? Colors.md3.secondary_container : Qt.alpha(Colors.md3.secondary_container, 0)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        HoverHandler {
            id: hoverHandler
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
            onEntered: {
                var yPos = Config.bar.position === 1 ? 0 : height;
                tooltipWindow.targetPos = mapToGlobal(width / 2, yPos);
                tooltipWindow.tipTitle = parent.tooltip;
                tooltipWindow.open = true;
            }
            onExited: tooltipWindow.open = false
        }
    }
}
