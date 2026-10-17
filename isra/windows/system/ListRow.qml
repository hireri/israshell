import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string title: ""
    property string sublabel: ""
    property bool clickable: false
    property real topRadius: 18
    property real bottomRadius: 18

    signal clicked

    default property alias trailing: trailingRow.data
    property alias leading: leadingSlot.data

    implicitHeight: Math.max(56, textCol.implicitHeight + 20)
    color: root.clickable && area.containsMouse ? Config.dim(Colors.md3.surface_container_high) : Config.dim(Colors.md3.surface_container)
    topLeftRadius: root.topRadius
    topRightRadius: root.topRadius
    bottomLeftRadius: root.bottomRadius
    bottomRightRadius: root.bottomRadius

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on topLeftRadius {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on bottomLeftRadius {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 18
            rightMargin: 18
        }
        spacing: 14

        Item {
            id: leadingSlot
            visible: leadingSlot.children.length > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: leadingSlot.childrenRect.width
            implicitHeight: leadingSlot.childrenRect.height
        }

        ColumnLayout {
            id: textCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
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

        Row {
            id: trailingRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
