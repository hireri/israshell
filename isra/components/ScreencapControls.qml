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

    function getScript(path) {
        if (!path || path === "")
            return "";
        return path.replace(/^~/, Quickshell.env("HOME"));
    }

    function isEnabled(name) {
        return !Config.screencap.blacklist.includes(name);
    }

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container
        } else { 
            Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
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

    BarTooltip {
        id: tooltipWindow
        yOffset: 8
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        leftPadding: 6
        rightPadding: 3

        ToolButton {
            visible: isEnabled("wallpaper")
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
                    anchors.leftMargin: 5
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
