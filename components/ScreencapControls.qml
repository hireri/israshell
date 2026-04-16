import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.icons
import Quickshell.Widgets

Rectangle {
    id: root

    function getScript(path) {
        if (!path || path === "")
            return "";
        return path.replace(/^~/, Quickshell.env("HOME"));
    }

    visible: Config.screencapEnabled && Config.screencap.blacklist.length < 5

    function isEnabled(name) {
        return Config.screencapEnabled && !Config.screencap.blacklist.includes(name);
    }

    property bool isRecording: false
    property string recordingTime: "00:00"
    property double startTime: 0
    property int missCount: 0

    property bool isRecognizing: false

    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.85) : Colors.md3.surface_container_high
    radius: 20
    implicitHeight: 32
    implicitWidth: rowLayout.width

    Process {
        id: recordScript
        command: ["sh", "-c", getScript(Config.screencap.recordPath)]
    }
    Process {
        id: screenshotScript
        command: ["sh", "-c", getScript(Config.screencap.screenshotPath)]
    }
    Process {
        id: ctsScript
        command: ["sh", "-c", getScript(Config.screencap.ctsPath)]
    }
    Process {
        id: ocrScript
        command: ["sh", "-c", getScript(Config.screencap.ocrPath)]
    }
    Process {
        id: songrecScript
        command: ["sh", "-c", getScript(Config.screencap.songrecPath)]
    }

    Process {
        id: checkProcess
        command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x gpu-screen-reco"]
        running: false
        onExited: exitCode => {
            var currentlyRunning = (exitCode === 0);

            if (currentlyRunning && !isRecording) {
                isRecording = true;
                startTime = Date.now();
            } else if (!currentlyRunning && isRecording) {
                isRecording = false;
                recordingTime = "00:00";
            }
        }
    }

    Process {
        id: checkSongrecProcess
        command: ["sh", "-c", "test -f /tmp/songrec_script.pid && kill -0 $(cat /tmp/songrec_script.pid) 2>/dev/null && exit 0 || exit 1"]
        running: false
        onExited: exitCode => {
            var currentlyRunning = (exitCode === 0);
            if (currentlyRunning !== isRecognizing) {
                isRecognizing = currentlyRunning;
            }
        }
    }

    Timer {
        id: checkTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!checkProcess.running) {
                checkProcess.running = true;
            }
            if (!checkSongrecProcess.running) {
                checkSongrecProcess.running = true;
            }
        }
    }

    Timer {
        id: displayTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!isRecording)
                return;

            var diff = Math.floor((Date.now() - startTime) / 1000);
            var hrs = Math.floor(diff / 3600);
            var mins = Math.floor((diff % 3600) / 60);
            var secs = diff % 60;

            recordingTime = hrs > 0 ? `${String(hrs).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}` : `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
        }
    }

    Window {
        id: tooltipWindow
        visible: false
        width: tooltipContent.width
        height: tooltipContent.height
        color: "transparent"
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowTransparentForInput

        property string title: ""
        property point targetPos: Qt.point(0, 0)
        x: targetPos.x - (width / 2)
        y: targetPos.y + 8

        onVisibleChanged: {
            if (visible)
                fadeIn.restart();
            else {
                tooltipContent.opacity = 0;
                tooltipContent.scale = 0.9;
            }
        }

        ParallelAnimation {
            id: fadeIn
            NumberAnimation {
                target: tooltipContent
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: tooltipContent
                property: "scale"
                from: 0.9
                to: 1.0
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: tooltipContent
            opacity: 0
            scale: 0.9
            implicitWidth: tooltipText.implicitWidth + 16
            height: tooltipText.implicitHeight + 12
            color: Colors.md3.surface_container_highest
            radius: 8
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline, 0.5)

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: tooltipWindow.title
                color: Colors.md3.on_surface
                font.pixelSize: 11
            }
        }
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        leftPadding: 6
        rightPadding: 3

        ToolButton {
            visible: isEnabled("screenshot")
            tooltip: "Screenshot"
            onClicked: screenshotScript.startDetached()
            ScreenshotIcon {
                iconSize: 18
                anchors.centerIn: parent
            }
        }

        ToolButton {
            visible: isEnabled("cts")
            tooltip: "Circle to Search"
            onClicked: ctsScript.startDetached()
            ImageSearchIcon {
                iconSize: 18
                anchors.centerIn: parent
            }
        }

        ToolButton {
            visible: isEnabled("ocr")
            tooltip: "OCR Text"
            onClicked: ocrScript.startDetached()
            OcrIcon {
                iconSize: 18
                anchors.centerIn: parent
            }
        }

        Item {
            visible: isEnabled("songrec")
            width: songrecBg.width
            height: 32

            Rectangle {
                id: songrecBg
                anchors.verticalCenter: parent.verticalCenter
                width: isRecognizing ? 38 : 32
                height: isRecognizing ? 26 : 32
                radius: 16
                color: isRecognizing ? Qt.alpha(Colors.md3.primary, 0.15) : (songrecHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent")

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

            SongrecIcon {
                iconSize: 18
                anchors.centerIn: parent
                color: isRecognizing ? Colors.md3.primary : Colors.md3.on_surface
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
                    isRecognizing = !isRecognizing;
                    songrecScript.startDetached();
                }
                onEntered: {
                    tooltipWindow.targetPos = mapToGlobal(width / 2, height);
                    tooltipWindow.title = isRecognizing ? "Stop Recognizing" : "Recognize Music";
                    tooltipWindow.visible = true;
                }
                onExited: tooltipWindow.visible = false
            }
        }

        Item {
            visible: isEnabled("record")
            height: 32
            width: recordBg.width

            ClippingRectangle {
                id: recordBg
                anchors.verticalCenter: parent.verticalCenter
                readonly property int textWidth: recordingTime.length > 5 ? 57 : 38
                width: isRecording ? 32 + 8 + textWidth : 32
                height: 26
                radius: 16
                color: isRecording ? Qt.alpha(Colors.md3.error, 0.15) : (recordHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent")

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

                RecordIcon {
                    id: recIcon
                    iconSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    color: isRecording ? Colors.md3.error : Colors.md3.on_surface
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
                    text: root.recordingTime
                    font.family: Config.fontMonospace
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.error
                    opacity: isRecording ? 1 : 0
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
                    tooltipWindow.targetPos = mapToGlobal(width / 2, height);
                    tooltipWindow.title = isRecording ? "Stop Recording" : "Start Recording";
                    tooltipWindow.visible = true;
                }
                onExited: tooltipWindow.visible = false
            }
        }
    }

    component ToolButton: Rectangle {
        property string tooltip
        signal clicked

        width: 32
        height: 32
        radius: 16

        color: hoverHandler.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent"

        HoverHandler {
            id: hoverHandler
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
            onEntered: {
                tooltipWindow.targetPos = mapToGlobal(width / 2, height);
                tooltipWindow.title = parent.tooltip;
                tooltipWindow.visible = true;
            }
            onExited: tooltipWindow.visible = false
        }
    }
}
