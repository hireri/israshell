//@ pragma UseQApplication
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import qs.style

Item {
    id: trayRoot
    required property var panelWindow

    implicitWidth: Math.max(trayContent.implicitWidth + 20, 0)
    height: 32
    visible: (SystemTray.items?.values.length ?? 0) > 0

    function getTrayName(item) {
        if (item.tooltipTitle && !item.tooltipTitle.includes("chrome_status_icon")) {
            return item.tooltipTitle;
        }
        if (item.title && !item.title.includes("chrome_status_icon")) {
            return item.title;
        }
        if (item.tooltipDescription && !item.tooltipDescription.includes("chrome_status_icon")) {
            return item.tooltipDescription;
        }
        if (item.id && !item.id.includes("chrome_status_icon")) {
            return item.id.charAt(0).toUpperCase() + item.id.slice(1);
        }
        return "Application";
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

    Rectangle {
        anchors.fill: parent
        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
        radius: 18

        Row {
            id: trayContent
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: delegateRoot
                    required property var modelData

                    readonly property bool isBlacklisted: Config.trayBlacklist.includes(modelData.id) || Config.trayBlacklist.includes(modelData.title)
                    visible: !isBlacklisted
                    implicitWidth: visible ? 20 : 0
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: iconImg
                        source: modelData?.icon ?? ""
                        anchors.fill: parent
                        sourceSize: Qt.size(20, 20)
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    Desaturate {
                        id: grayIcon
                        anchors.fill: iconImg
                        source: iconImg
                        desaturation: 1.0
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: iconImg
                        source: grayIcon
                        color: Qt.alpha(Colors.md3.on_surface, 0.4)
                        visible: Config.tintTrayIcons
                    }

                    Image {
                        anchors.fill: parent
                        source: modelData?.icon ?? ""
                        sourceSize: Qt.size(20, 20)
                        fillMode: Image.PreserveAspectFit
                        visible: !Config.tintTrayIcons
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onEntered: {
                            var prettyName = trayRoot.getTrayName(modelData);

                            if (prettyName) {
                                var globalCoord = delegateRoot.mapToGlobal(delegateRoot.width / 2, delegateRoot.height);
                                tooltipWindow.targetPos = globalCoord;
                                tooltipWindow.title = prettyName;
                                tooltipWindow.visible = true;
                            }
                        }

                        onExited: tooltipWindow.visible = false

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                modelData?.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                const pos = mapToItem(panelWindow.contentItem, mouse.x, mouse.y);
                                modelData?.display(panelWindow, pos.x, pos.y);
                            }
                        }
                    }
                }
            }
        }
    }
}
