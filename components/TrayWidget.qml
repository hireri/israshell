import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

import qs.style

Rectangle {
    required property var panelWindow

    visible: (SystemTray.items?.values?.length ?? 0) > 0
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 12
    width: Math.max(trayContent.implicitWidth + 20, 0)
    height: 32

    Row {
        id: trayContent
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData
                required property int index

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: modelData?.icon ?? ""
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            modelData?.activate();
                        else if (mouse.button === Qt.MiddleButton)
                            modelData?.secondaryActivate();
                        else if (mouse.button === Qt.RightButton) {
                            const pos = mapToItem(null, mouse.x, mouse.y);
                            modelData?.display(panelWindow, pos.x, pos.y);
                        }
                    }
                }
            }
        }
    }
}
