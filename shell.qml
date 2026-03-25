//@ pragma UseQApplication
import Quickshell
import QtQuick

import qs.components
import qs.style

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 42

            color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.8) : Colors.md3.surface_container

            Item {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                ActiveWindow {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    MediaPlayer {}
                    Workspaces {
                        panelWindow: window
                    }
                    BarClock {}
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    TrayWidget {
                        panelWindow: window
                    }
                    QuickSettings {}
                }
            }
        }
    }
}
