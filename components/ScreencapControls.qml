import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.icons

Rectangle {
    id: root

    function getScript(path) {
        if (!path || path === "")
            return "";
        return path.replace(/^~/, Quickshell.env("HOME"));
    }

    visible: Config.screencapEnabled && Config.screencap.blacklist.length < 4

    function isEnabled(name) {
        return Config.screencapEnabled && !Config.screencap.blacklist.includes(name);
    }

    property bool isRecording: false
    property string recordingTime: "00:00"
    property double startTime: 0

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
        id: checkProcess
        command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x gpu-screen-recorder"]
        running: false
        onExited: exitCode => {
            var wasRecording = isRecording;
            isRecording = (exitCode === 0);
            if (isRecording && !wasRecording)
                startTime = Date.now();
            else if (!isRecording)
                recordingTime = "00:00";
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProcess.running = true
    }

    Timer {
        interval: 1000
        running: isRecording
        repeat: true
        onTriggered: {
            var diff = Math.round((Date.now() - startTime) / 1000);
            var hrs = Math.floor(diff / 3600);
            var mins = Math.floor((diff % 3600) / 60);
            var secs = diff % 60;
            recordingTime = hrs > 0 ? `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}` : `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
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
        y: targetPos.y + 14

        onVisibleChanged: {
            if (visible) {
                fadeIn.restart();
            } else {
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
        rightPadding: isRecording ? 3 : 6

        Behavior on rightPadding {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

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

        Rectangle {
            visible: isEnabled("record")

            width: isRecording ? 32 + timeMetrics.width + 6 : 32
            height: 32
            radius: 16

            color: isRecording ? Qt.alpha(Colors.md3.error, 0.15) : (recordHover.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent")

            anchors.verticalCenter: parent.verticalCenter

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

            Row {
                anchors.centerIn: parent
                spacing: 0

                Item {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    RecordIcon {
                        iconSize: 18
                        anchors.centerIn: parent
                        color: isRecording ? Colors.md3.error : Colors.md3.on_surface

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                Item {
                    width: isRecording ? timeMetrics.width + 6 : 0
                    height: recordingText.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    opacity: isRecording ? 1 : 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    TextMetrics {
                        id: timeMetrics
                        font: recordingText.font
                        text: root.recordingTime.length > 5 ? "00:00:00" : "00:00"
                    }

                    Text {
                        id: recordingText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.recordingTime
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.md3.error
                        scale: isRecording ? 1.0 : 0.8
                        transformOrigin: Item.Left

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                            }
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
