import QtQuick
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    readonly property bool barAtBottom: Config.bar.position === 1
    readonly property alias toolbarItem: toolbar

    anchors.fill: parent

    Rectangle {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: root.barAtBottom ? parent.top : undefined
        anchors.bottom: root.barAtBottom ? undefined : parent.bottom
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        radius: height / 2
        height: 44
        width: toolbarRow.implicitWidth + 16
        color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.15)

        Row {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 8
                text: Localization.t("background.editing_widgets")
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 12
            }

            Rectangle {
                id: undoButton
                width: 32
                height: 32
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: undoMouse.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : "transparent"
                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "history"
                    iconSize: 16
                    color: Colors.md3.on_surface_variant
                }

                MouseArea {
                    id: undoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: EditModeService.undoChanges()
                }
            }

            Rectangle {
                id: doneButton
                width: 32
                height: 32
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.md3.primary

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: doneMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "check"
                    iconSize: 16
                    color: Colors.md3.on_primary
                }

                MouseArea {
                    id: doneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: EditModeService.disable()
                }
            }
        }
    }
}
