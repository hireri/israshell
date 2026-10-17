pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property string sublabel: ""
    property string tone: "neutral"
    property int valueSize: 28
    property bool clickable: false

    signal clicked

    default property alias content: slot.data
    property alias actions: actionRow.data
    property alias aside: asideSlot.data

    readonly property bool _tonal: root.tone !== "neutral"
    readonly property color _bg: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "ok" ? Colors.md3.secondary_container : root.tone === "primary" ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container)
    readonly property color _fg: !root._tonal ? Colors.md3.on_surface : root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "ok" ? Colors.md3.on_secondary_container : Colors.md3.on_primary_container

    implicitHeight: Math.max(layout.implicitHeight + 32, 88)
    radius: 20
    color: root._bg
    scale: root.clickable && area.pressed ? 0.98 : 1

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root._fg
        opacity: root.clickable && area.containsMouse ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
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
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 18
            rightMargin: 18
        }
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                visible: root.label !== ""
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: root._tonal ? Qt.alpha(root._fg, 0.8) : Colors.md3.on_surface_variant
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.value !== ""
                text: root.value
                font.family: Config.fontFamily
                font.pixelSize: root.valueSize
                font.weight: Font.Medium
                color: root._fg
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.sublabel !== ""
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: root._tonal ? Qt.alpha(root._fg, 0.8) : Colors.md3.outline
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            ColumnLayout {
                id: slot
                Layout.fillWidth: true
                spacing: 8
            }

            Row {
                id: actionRow
                Layout.topMargin: actionRow.children.length > 0 ? 6 : 0
                spacing: 8
            }
        }

        Item {
            id: asideSlot
            visible: asideSlot.children.length > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: asideSlot.childrenRect.width
            implicitHeight: asideSlot.childrenRect.height
        }
    }
}
