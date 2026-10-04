pragma ComponentBehavior: Bound
import QtQuick
import qs.icons
import qs.style

Rectangle {
    id: root

    property var entries: []
    property bool open: false
    property bool opensUp: false

    signal triggered(int index)

    width: 168
    height: col.implicitHeight + 8
    radius: 16
    color: Colors.md3.surface_container
    border.width: 1
    border.color: Qt.alpha(Colors.md3.on_surface, 0.3)
    opacity: 0
    scale: 0.9
    visible: opacity > 0
    transformOrigin: opensUp ? Item.BottomRight : Item.TopRight
    layer.enabled: true
    layer.smooth: true

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "scale"; to: 0.9; duration: 110; easing.type: Easing.InCubic }
    }

    Column {
        id: col
        y: 3
        width: parent.width

        Repeater {
            model: root.entries

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool header: modelData.header ?? false
                readonly property color tone: modelData.danger ? Colors.md3.error : (header ? Colors.md3.on_surface_variant : Colors.md3.on_surface)

                width: col.width
                height: 36

                Rectangle {
                    id: hover
                    anchors {
                        fill: parent
                        leftMargin: 6
                        rightMargin: 6
                        topMargin: 2
                        bottomMargin: 2
                    }
                    radius: 12
                    color: Colors.md3.on_surface
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: 60 }
                    }
                }

                MaterialIcon {
                    id: icon
                    visible: !!row.modelData.icon
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    name: row.modelData.icon ?? ""
                    iconSize: 16
                    color: row.tone
                }

                Text {
                    anchors {
                        left: icon.visible ? icon.right : parent.left
                        leftMargin: icon.visible ? 7 : 14
                        right: parent.right
                        rightMargin: 34
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.modelData.label
                    color: row.tone
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    visible: row.modelData.checked ?? false
                    anchors {
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    name: "check"
                    iconSize: 14
                    color: Colors.md3.primary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !row.header
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: hover.opacity = 0.08
                    onExited: hover.opacity = 0
                    onClicked: root.triggered(row.index)
                }
            }
        }
    }
}
