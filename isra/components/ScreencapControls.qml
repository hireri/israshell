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

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else { 
            Qt.alpha(Colors.md3.surface_container_high, 0.8)
        }
    }   

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    radius: 20
    implicitHeight: 32
    implicitWidth: rowLayout.width

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
    }

    Process {
        id: colorPickerScript
        command: ["hyprpicker", "--autocopy"]
    }

    BarTooltip {
        id: tooltipWindow
        screen: root.panelWindow.screen
        panelWindow: root.panelWindow
        yOffset: 4
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        leftPadding: 3
        rightPadding: 3

        Item {
            visible: isEnabled("wallpaper")
            width: 32
            height: 32

            ToolButton {
                anchors.centerIn: parent
                height: 26
                tooltip: "Wallpaper"
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

        ToolButton {
            visible: isEnabled("screenshot")
            tooltip: "Screenshot"
            onClicked: screenshotScript.startDetached()
            MaterialIcon {
                name: "screenshot"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }

        ToolButton {
            visible: isEnabled("cts")
            tooltip: "Circle to Search"
            onClicked: ctsScript.startDetached()
            MaterialIcon {
                name: "image-search"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }

        ToolButton {
            visible: isEnabled("ocr")
            tooltip: "OCR Text"
            onClicked: ocrScript.startDetached()
            MaterialIcon {
                name: "ocr"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
            }
        }

        ToolButton {
            visible: isEnabled("colorpicker")
            tooltip: "Color Picker"
            onClicked: colorPickerScript.startDetached()
            MaterialIcon {
                name: "colorize"
                iconSize: 18
                anchors.centerIn: parent
                color: Colors.md3.on_surface
                transitionType: "none"
            }
        }

        Item {
            id: lsItem
            visible: isEnabled("localsend")
            width: lsBg.width
            height: 32

            readonly property string lsState: lsDrop.containsDrag ? "drag" : LocalSendService.pillState

            readonly property string lsLabel: {
                switch (lsState) {
                case "drag":
                    return "drop to send";
                case "staged":
                    return String(LocalSendService.attachedFiles.length);
                case "sending":
                    return Math.round(100 * LocalSendService.transferProgress) + "%";
                case "waiting":
                    return "waiting";
                case "incoming":
                    return "incoming";
                case "pin":
                    return "PIN";
                case "done":
                    switch (LocalSendService.lastResult?.kind) {
                    case "sent":
                        return "sent";
                    case "received":
                        return "received";
                    case "declined":
                        return "declined";
                    case "recv_timeout":
                        return "expired";
                    default:
                        return "cancelled";
                    }
                case "error":
                    return "failed";
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

                MaterialShape {
                    id: lsSpinner
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    visible: lsItem.lsState === "sending"
                    shapeSize: 16
                    color: lsItem.lsFg
                    shapes: ["pill", "sunny", "cookie4", "oval", "softBurst", "cookie9", "pentagon"]

                    property real _cycleStart: 0

                    SequentialAnimation on rotation {
                        running: lsSpinner.visible
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: lsSpinner._cycleStart
                            to: lsSpinner._cycleStart + 45
                            duration: 650
                            easing.type: Easing.Linear
                        }
                        NumberAnimation {
                            from: lsSpinner._cycleStart + 45
                            to: lsSpinner._cycleStart + 85
                            duration: 150
                            easing.type: Easing.InQuad
                        }
                        ScriptAction {
                            script: lsSpinner.roundedPolygon = lsSpinner._pick()
                        }
                        NumberAnimation {
                            from: lsSpinner._cycleStart + 85
                            to: lsSpinner._cycleStart + 100
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                        ScriptAction {
                            script: lsSpinner._cycleStart = (lsSpinner._cycleStart + 100) % 360
                        }
                    }
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
                    tooltipWindow.tipTitle = "LocalSend";
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

        Item {
            visible: isEnabled("songrec")
            width: songrecBg.width
            height: 32

            Rectangle {
                id: songrecBg
                anchors.verticalCenter: parent.verticalCenter
                width: ScreencapService.isRecognizing ? 38 : 32
                height: ScreencapService.isRecognizing ? 26 : 32
                radius: 16
                color: ScreencapService.isRecognizing ? Qt.alpha(Colors.md3.primary, 0.15) : (songrecHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent")

                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
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
                color: ScreencapService.isRecognizing ? Colors.md3.primary : Colors.md3.on_surface
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
                    ScreencapService.isRecognizing = !ScreencapService.isRecognizing;
                    songrecScript.startDetached();
                }
                onEntered: {
                    var yPos = Config.bar.position === 1 ? 0 : height;
                    tooltipWindow.targetPos = mapToGlobal(width / 2, yPos);
                    tooltipWindow.tipTitle = ScreencapService.isRecognizing ? "Stop Recognizing" : "Recognize Music";
                    tooltipWindow.open = true;
                }
                onExited: tooltipWindow.open = false
            }
        }

        Item {
            visible: isEnabled("record")
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
                    tooltipWindow.tipTitle = ScreencapService.isRecording ? "Stop Recording" : "Start Recording";
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
