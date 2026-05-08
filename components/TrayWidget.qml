import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

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

    BarTooltip {
        id: tooltipWindow
        yOffset: 14
    }

    Rectangle {
        anchors.fill: parent
        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
        radius: 18

        Row {
            id: trayContent
            anchors.centerIn: parent
            spacing: 12

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
                        visible: !Config.tintTrayIcons
                    }

                    Loader {
                        active: Config.tintTrayIcons
                        anchors.fill: iconImg
                        sourceComponent: MultiEffect {
                            source: iconImg
                            saturation: -1.0
                            colorization: 1.0
                            colorizationColor: Qt.alpha(Colors.md3.on_surface, 0.4)
                        }
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
                                var yPos = Config.barPosition === 1 ? 0 : delegateRoot.height;
                                var globalCoord = delegateRoot.mapToGlobal(delegateRoot.width / 2, yPos);
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
