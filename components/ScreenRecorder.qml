import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.icons

Rectangle {
    id: root

    property bool isRecording: false
    property string recordingTime: "00:00"
    property double startTime: 0

    property real bgPadding: isRecording ? 24 : 12

    Behavior on bgPadding {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 18
    implicitHeight: 32

    implicitWidth: rowLayout.width + bgPadding

    Process {
        id: checkProcess
        command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x gpu-screen-recorder"]
        running: false

        onExited: (exitCode, exitStatus) => {
            var wasRecording = isRecording;
            isRecording = (exitCode === 0);
            if (isRecording && !wasRecording)
                startTime = Date.now();
            else if (!isRecording)
                recordingTime = "00:00";
        }
    }

    Process {
        id: toggleProcess
        command: ["sh", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/record.sh"]
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

            if (hrs > 0) {
                recordingTime = hrs.toString().padStart(2, '0') + ":" + mins.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0');
            } else {
                recordingTime = mins.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0');
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: toggleProcess.startDetached()
        cursorShape: Qt.PointingHandCursor
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent

        RecordIcon {
            id: recordIcon
            iconSize: 20
            color: isRecording ? Colors.md3.error : Colors.md3.on_surface
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Item {
            width: isRecording ? timeMetrics.width + 8 : 0
            height: recordingText.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            opacity: isRecording ? 1 : 0

            TextMetrics {
                id: timeMetrics
                font: recordingText.font
                text: root.recordingTime.length > 5 ? "00:00:00" : "00:00"
            }

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

            Text {
                id: recordingText
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.recordingTime
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: Colors.md3.on_surface
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
}
