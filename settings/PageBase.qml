import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import qs.style

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property int maxWidth: 720
    default property alias content: body.data

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: inner.implicitHeight
        clip: true

        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        flickDeceleration: 1500
        maximumFlickVelocity: 2500

        WheelHandler {
            onWheel: event => {
                flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - event.angleDelta.y * 0.5));
            }
        }

        ColumnLayout {
            id: inner
            width: Math.min(flick.width, root.maxWidth)
            x: (flick.width - width) / 2
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 28
                Layout.bottomMargin: 16
                spacing: 4

                Text {
                    text: root.title
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                    font.letterSpacing: -0.3
                    color: Colors.md3.on_surface
                }

                Text {
                    text: root.subtitle
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.outline
                    visible: root.subtitle !== ""
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.5
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 20
                Layout.bottomMargin: 28
                spacing: 16
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
