import QtQuick
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property bool open: false
    readonly property alias cardItem: card
    readonly property bool barAtBottom: Config.bar.position === 1

    function toggle(): void {
        root.open = !root.open;
    }
    function close(): void {
        root.open = false;
    }

    width: card.width
    height: card.height
    visible: opacity > 0.01
    opacity: root.open ? 1 : 0

    readonly property real cols: 2
    readonly property real tileSize: 78
    readonly property real gap: 8
    readonly property real pad: 10

    readonly property bool clockOn: Config.desktopClock ?? true
    readonly property bool weyesOn: Config.weyes.enabled ?? false
    readonly property var musicEntry: DesktopWidgetService.firstOf("music")
    readonly property int photoCount: DesktopWidgetService.countOf("photo")

    readonly property var catalog: [
        { type: "clock", label: Localization.t("widgetDrawer.clock"), icon: "analog-clock", on: root.clockOn, count: 0, stackable: false },
        { type: "weyes", label: Localization.t("widgetDrawer.weyes"), icon: "visibility", on: root.weyesOn, count: 0, stackable: false },
        { type: "music", label: Localization.t("widgetDrawer.music"), icon: "music-note", on: root.musicEntry !== null, count: 0, stackable: false },
        { type: "photo", label: Localization.t("widgetDrawer.photo"), icon: "image", on: root.photoCount > 0, count: root.photoCount, stackable: true }
    ]

    function activate(item) {
        switch (item.type) {
        case "clock":
            Config.update({ desktopClock: !root.clockOn });
            break;
        case "weyes":
            Config.update({ weyes: Object.assign({}, Config.weyes, { enabled: !root.weyesOn }) });
            break;
        case "music":
            if (root.musicEntry)
                DesktopWidgetService.removeEntry(root.musicEntry.id);
            else
                DesktopWidgetService.addWidget("music");
            break;
        case "photo":
            DesktopWidgetService.addWidget("photo");
            break;
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    scale: root.open ? 1 : 0.88
    transformOrigin: root.barAtBottom ? Item.Bottom : Item.Top
    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: card
        width: root.cols * root.tileSize + (root.cols - 1) * root.gap + root.pad * 2
        height: grid.implicitHeight + root.pad * 2 + titleText.implicitHeight + 6

        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        radius: 20
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Text {
            id: titleText
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: root.pad
            }
            text: Localization.t("widgetDrawer.title")
            color: Colors.md3.on_surface_variant
            font.family: Config.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Grid {
            id: grid
            anchors {
                top: titleText.bottom
                topMargin: 6
                horizontalCenter: parent.horizontalCenter
            }
            columns: root.cols
            spacing: root.gap

            Repeater {
                model: root.catalog

                Rectangle {
                    id: tile
                    required property var modelData

                    width: root.tileSize
                    height: root.tileSize
                    radius: 16
                    color: tile.modelData.on
                        ? Colors.md3.primary_container
                        : (tileMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tile.modelData.icon
                            filled: tile.modelData.on
                            iconSize: 24
                            color: tile.modelData.on ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: tile.modelData.on ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 4
                        }
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.md3.primary
                        visible: tile.modelData.stackable && tile.modelData.count > 0

                        Text {
                            anchors.centerIn: parent
                            text: tile.modelData.count
                            font.family: Config.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Colors.md3.on_primary
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(tile.modelData)
                    }
                }
            }
        }
    }
}
