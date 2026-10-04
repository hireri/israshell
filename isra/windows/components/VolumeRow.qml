import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string glyph: "󰕾"
    property string mutedGlyph: "󰖁"
    property string label
    property string sublabel
    property bool muted
    property real volume
    property real maxVolume: 1.5
    property color accent: Colors.md3.primary
    property int buttonSize: 38
    property int rowHeight: 48
    property int leftInset: 10
    property int rightInset: 16

    signal muteToggled
    signal volumeMoved(real volume)

    implicitWidth: parent?.width ?? 0
    implicitHeight: root.rowHeight

    RowLayout {
        anchors {
            fill: parent
            leftMargin: root.leftInset
            rightMargin: root.rightInset
        }
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.buttonSize
            implicitHeight: root.buttonSize
            radius: root.muted ? width / 2 : Math.round(root.buttonSize * 0.32)
            color: root.muted ? Colors.md3.error_container : Config.dim(Colors.md3.surface_container_high)

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.muted ? root.mutedGlyph : root.glyph
                font.pixelSize: 16
                font.family: Config.fontMonospace
                color: root.muted ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.muteToggled()
            }
        }

        ColumnLayout {
            visible: root.label !== ""
            Layout.preferredWidth: 96
            Layout.maximumWidth: 96
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.on_surface
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.sublabel !== ""
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.outline
                elide: Text.ElideRight
            }
        }

        TrackSlider {
            Layout.fillWidth: true
            Layout.minimumWidth: 80
            from: 0
            to: root.maxVolume
            stepSize: 0.01
            fillColor: root.accent
            value: root.volume
            onMoved: root.volumeMoved(value)
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.volume * 100) + "%"
            font.family: Config.fontMonospace
            font.pixelSize: 11
            color: Colors.md3.outline
        }
    }
}
