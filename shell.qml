//@ pragma UseQApplication
import Quickshell
import QtQuick

import qs.components
import qs.style

ShellRoot {

    NotificationPopup {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true

            implicitHeight: Config.floatingBar ? 56 : 44

            color: "transparent"
            exclusiveZone: implicitHeight

            Item {
                anchors.fill: parent
                anchors.leftMargin: Config.floatingBar ? 12 : 0
                anchors.rightMargin: Config.floatingBar ? 12 : 0
                anchors.topMargin: Config.floatingBar ? 8 : 0

                Rectangle {
                    id: barContainer
                    anchors.fill: parent

                    radius: Config.floatingBar ? 18 : 0

                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container

                    border.width: Config.floatingBar ? 1 : 0
                    border.color: Config.transparentBar ? Qt.alpha(Colors.md3.outline_variant, 0.5) : Colors.md3.outline_variant

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: parent.radius + 2
                        color: Qt.alpha(Colors.md3.shadow, 0.15)
                        z: -1
                    }

                    Item {
                        anchors.fill: parent
                        anchors.rightMargin: 8

                        ActiveWindow {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 12

                            MediaPlayer {}
                            Workspaces {
                                panelWindow: window
                            }
                            BarClock {}
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            TrayWidget {
                                panelWindow: window
                            }
                            QuickSettings {
                                panelWindow: window
                            }
                        }
                    }
                }
            }
        }
    }
}
