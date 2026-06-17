import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell

import qs.services
import qs.style

Item {
    id: root

    ListModel { id: passwordModel }

    TextInput {
        id: hiddenPasswordInput
        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        enabled: !LockscreenService.unlockInProgress

        onActiveFocusChanged: {
            if (!activeFocus)
                forceActiveFocus()
        }

        onTextChanged: {
            LockscreenService.currentText = text
            while (passwordModel.count < text.length)  passwordModel.append({})
            while (passwordModel.count > text.length)  passwordModel.remove(passwordModel.count - 1)
        }

        Keys.onReturnPressed: LockscreenService.tryUnlock()
        Keys.onEnterPressed:  LockscreenService.tryUnlock()

        Connections {
            target: LockscreenService

            function onCurrentTextChanged() {
                if (hiddenPasswordInput.text !== LockscreenService.currentText)
                    hiddenPasswordInput.text = LockscreenService.currentText
            }
            function onUnlocked() {
                hiddenPasswordInput.text = ""
            }
            function onShowFailureChanged() {
                if (LockscreenService.showFailure) {
                    shakeAnimation.start()
                    hiddenPasswordInput.text = ""
                }
            }
        }
    }

    Item {
        anchors {
            bottom: parent.bottom
            bottomMargin: 48
            horizontalCenter: parent.horizontalCenter
        }
        width: outerPill.width
        height: outerPill.height

        Rectangle {
            id: outerPill
            height: 64
            width: mainLayout.implicitWidth + 24
            radius: height / 2
            color: Colors.md3.surface_container

            SequentialAnimation {
                id: shakeAnimation
                loops: 2
                PropertyAnimation { target: outerPill; property: "x"; to: -12; duration: 40; easing.type: Easing.InOutQuad }
                PropertyAnimation { target: outerPill; property: "x"; to:  12; duration: 80; easing.type: Easing.InOutQuad }
                PropertyAnimation { target: outerPill; property: "x"; to:   0; duration: 40; easing.type: Easing.InOutQuad }
            }

            RowLayout {
                id: mainLayout
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 12
                }
                spacing: 16

                RowLayout {
                    spacing: 10

                    ClippingRectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: Colors.md3.surface_container_high

                        Image {
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.face"
                            sourceSize: Qt.size(44, 44)
                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                        }
                    }

                    Text {
                        text: Quickshell.env("USER")
                        color: Colors.md3.on_surface
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    id: inputPill
                    height: 44
                    width: 200
                    radius: height / 2
                    color: Colors.md3.surface_container_lowest

                    Text {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 16
                        }
                        text: "Password"
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 14
                        opacity: 0.6
                        visible: hiddenPasswordInput.text.length === 0
                    }

                    ListView {
                        id: dotListView
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 12
                        }
                        clip: true
                        model: passwordModel
                        orientation: ListView.Horizontal
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentX {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        onContentWidthChanged: {
                            contentX = contentWidth > width ? contentWidth - width : 0
                        }

                        delegate: Item {
                            width: 12
                            height: dotListView.height

                            Rectangle {
                                id: dotVisual
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                radius: 4
                                color: Colors.md3.on_surface

                                SequentialAnimation {
                                    running: LockscreenService.unlockInProgress
                                    loops: Animation.Infinite

                                    ParallelAnimation {
                                        NumberAnimation { target: dotVisual; property: "opacity"; to: 0.3; duration: 750; easing.type: Easing.InOutQuad }
                                        NumberAnimation { target: dotVisual; property: "scale";   to: 0.85; duration: 750; easing.type: Easing.InOutQuad }
                                    }
                                    ParallelAnimation {
                                        NumberAnimation { target: dotVisual; property: "opacity"; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                                        NumberAnimation { target: dotVisual; property: "scale";   to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }

                        add: Transition {
                            NumberAnimation { property: "scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
                        }
                        remove: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "scale"; to: 0; duration: 120; easing.type: Easing.InQuad }
                                NumberAnimation { property: "width"; to: 0; duration: 120; easing.type: Easing.InQuad }
                            }
                        }
                        displaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 160; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
