pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.style
import "lockLayout.js" as Layouts

Item {
    id: root

    readonly property string layout: Layouts.valid(Config.lockscreen.layout)
    property string shown: ""

    Component.onCompleted: shown = layout
    onLayoutChanged: if (shown !== "" && shown !== layout) swap.restart()

    SequentialAnimation {
        id: swap
        NumberAnimation { target: loader; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutCubic }
        ScriptAction { script: root.shown = root.layout }
        NumberAnimation { target: loader; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }

    component FramedField: Rectangle {
        implicitHeight: 64
        radius: height / 2
        color: Colors.md3.surface_container

        LockField {
            x: 10
            y: 10
            width: parent.width - 20
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.shown === "" ? null : root.shown === "corners" ? cornersComp : root.shown === "center" ? centerComp : dockComp
    }

    Component {
        id: dockComp
        Item {
            LockStatus {
                anchors {
                    top: parent.top
                    topMargin: 24
                    right: parent.right
                    rightMargin: 32
                }
            }

            Column {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 32
                }
                spacing: 12

                LockMedia {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 380
                }

                Rectangle {
                    width: Math.min(520, root.width - 64)
                    height: 64
                    radius: height / 2
                    color: Colors.md3.surface_container

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        LockIdentity {
                            showStatus: false
                        }
                        LockField {
                            Layout.fillWidth: true
                        }
                        LockPower {
                            z: 10
                            compact: true
                            opensUp: true
                        }
                    }
                }
            }
        }
    }

    Component {
        id: cornersComp
        Item {
            LockMedia {
                x: 64
                y: 48
                width: 380
            }

            RowLayout {
                anchors {
                    top: parent.top
                    topMargin: 48
                    right: parent.right
                    rightMargin: 64
                }
                spacing: 16

                LockStatus {}
                LockPower { z: 10 }
            }

            Column {
                anchors {
                    right: parent.right
                    rightMargin: 64
                    bottom: parent.bottom
                    bottomMargin: 96
                }
                width: 340
                spacing: 12

                LockIdentity {
                    avatarSize: 56
                    nameSize: 16
                }
                FramedField {
                    width: parent.width
                }
            }
        }
    }

    Component {
        id: centerComp
        Item {
            readonly property real clockH: Math.max(0, WallpaperService.clockRenderHeight - 20)

            LockIdentity {
                x: 64
                y: 48
                showStatus: false
            }

            RowLayout {
                anchors {
                    top: parent.top
                    topMargin: 48
                    right: parent.right
                    rightMargin: 64
                }
                spacing: 16

                LockStatus {}
                LockPower { z: 10 }
            }

            FramedField {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height / 2 + parent.clockH / 2
                width: 360
            }

            LockMedia {
                x: 64
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 48
                width: 380
            }
        }
    }
}
