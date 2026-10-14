pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.style
import qs.icons

Item {
    id: root

    property string currentIcon: ""
    property bool active: true
    signal picked(string name)

    readonly property real cell: 44
    property string hovered: ""

    implicitWidth: 350
    implicitHeight: 36 + 8 + 190 + 6 + 16

    Rectangle {
        id: filterBox
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        radius: 18
        color: Config.dim(Colors.md3.surface_container_high)
        border.width: filterInput.activeFocus ? 1.5 : 1
        border.color: filterInput.activeFocus ? Colors.md3.primary : Colors.md3.outline_variant

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            iconSize: 16
            color: Colors.md3.outline
            transitionType: "none"
        }

        TextInput {
            id: filterInput
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 12
            clip: true

            Text {
                visible: filterInput.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: Localization.t("powerMenuPage.filter_icons")
                font: filterInput.font
                color: Colors.md3.outline
            }
        }
    }

    FolderListModel {
        id: dir
        folder: root.active ? "file://" + Quickshell.shellDir + "/icons/outline" : ""
        nameFilters: ["*" + filterInput.text.trim().toLowerCase().replace(/[^a-z0-9-]/g, "") + "*.svg"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    GridView {
        id: grid
        anchors.top: filterBox.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: 190
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: Math.floor(width / Math.max(1, Math.floor(width / root.cell)))
        cellHeight: root.cell
        model: dir

        delegate: Item {
            id: cellItem
            required property string fileBaseName
            readonly property bool isCurrent: cellItem.fileBaseName === root.currentIcon

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.centerIn: parent
                width: root.cell - 8
                height: root.cell - 8
                radius: 12
                color: cellItem.isCurrent ? Colors.md3.primary_container : (cellMa.containsMouse ? Colors.md3.surface_container_highest : "transparent")

                MaterialIcon {
                    anchors.centerIn: parent
                    name: cellItem.fileBaseName
                    iconSize: 22
                    color: cellItem.isCurrent ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                    transitionType: "none"
                }
            }

            MouseArea {
                id: cellMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered = cellItem.fileBaseName
                onExited: if (root.hovered === cellItem.fileBaseName)
                    root.hovered = ""
                onClicked: root.picked(cellItem.fileBaseName)
            }
        }
    }

    Text {
        anchors.top: grid.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.leftMargin: 4
        text: root.hovered !== "" ? root.hovered : root.currentIcon
        font.family: Config.fontMonospace
        font.pixelSize: 11
        color: Colors.md3.outline
    }
}
