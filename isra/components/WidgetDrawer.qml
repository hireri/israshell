import QtQuick
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property bool open: false
    property var hostScreen: null

    readonly property bool coexistsWithMode: true

    function toggle(): void {
        if (root.open)
            root.close();
        else
            root.show();
    }
    function show(): void {
        if (root.open)
            return;
        root.open = true;
        PanelService.opened(root, root.hostScreen);
    }
    function close(): void {
        if (!root.open)
            return;
        root.open = false;
        PanelService.closed(root);
    }

    Component.onDestruction: {
        PanelService.closed(root);
        if (root._cursorAcquired)
            CursorService.release();
    }

    property bool _cursorAcquired: false
    onOpenChanged: {
        if (root.open === root._cursorAcquired)
            return;
        if (root.open)
            CursorService.acquire();
        else
            CursorService.release();
        root._cursorAcquired = root.open;
    }

    readonly property real _cursorWindowX: CursorService.x - (root.hostScreen?.x ?? 0)
    readonly property real _cursorWindowY: CursorService.y - (root.hostScreen?.y ?? 0)

    visible: opacity > 0.01
    opacity: 0

    readonly property real cols: 4
    readonly property real tileW: 116
    readonly property real previewH: 82
    readonly property real gap: 8
    readonly property real pad: 12

    readonly property real cardW: root.cols * root.tileW + (root.cols - 1) * root.gap + root.pad * 2
    readonly property real cardH: grid.implicitHeight + root.pad * 2 + titleText.implicitHeight + 8

    function activate(descriptor): void {
        const type = descriptor.type;
        if (!WidgetCatalog.available(type))
            return;
        if (WidgetCatalog.toggles(type) && WidgetCatalog.present(type)) {
            EditModeService.clearSelection();
            WidgetCatalog.removeType(type);
            return;
        }
        if (!WidgetCatalog.canAdd(type))
            return;
        const newId = WidgetCatalog.add(type, root.hostScreen);
        if (newId)
            EditModeService.select(newId, root.hostScreen);
    }

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
            topMargin: 8
            horizontalCenter: parent.horizontalCenter
        }
        columns: root.cols
        spacing: root.gap

        Repeater {
            model: WidgetCatalog.types

            Rectangle {
                id: tile
                required property var modelData

                readonly property bool available: WidgetCatalog.available(modelData.type)
                readonly property bool present: WidgetCatalog.present(modelData.type)
                readonly property int count: WidgetCatalog.count(modelData.type)
                readonly property bool interactive: tile.available && (WidgetCatalog.canAdd(modelData.type) || (WidgetCatalog.toggles(modelData.type) && tile.present))

                width: root.tileW
                height: root.previewH + labelCol.implicitHeight + 14
                radius: 16
                opacity: tile.available ? 1 : 0.4

                readonly property color hoverColor: Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
                color: tileMouse.containsMouse && tile.interactive ? tile.hoverColor : Qt.alpha(tile.hoverColor, 0)

                border.width: (tile.present && !tile.modelData.stackable) ? 2 : 0
                border.color: Colors.md3.primary

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Item {
                    id: previewPane
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: 8
                        leftMargin: 6
                        rightMargin: 6
                    }
                    height: root.previewH
                    clip: true

                    Loader {
                        id: previewLoader
                        active: tile.available
                        sourceComponent: tile.modelData.preview

                        readonly property size nativeSize: WidgetCatalog.previewSize(tile.modelData.type)
                        readonly property bool isWeyes: tile.modelData.type === "weyes"

                        width: previewLoader.nativeSize.width
                        height: previewLoader.nativeSize.height
                        anchors.centerIn: parent
                        scale: Math.min(1, (previewPane.width - 8) / width, (previewPane.height - 8) / height)

                        Binding {
                            target: previewLoader.item
                            property: "tracking"
                            value: root.open
                            when: previewLoader.isWeyes && previewLoader.status === Loader.Ready && previewLoader.item && previewLoader.item.hasOwnProperty("tracking")
                        }
                        Binding {
                            target: previewLoader.item
                            property: "targetX"
                            value: previewLoader.mapFromItem(null, root._cursorWindowX, root._cursorWindowY).x
                            when: previewLoader.isWeyes && previewLoader.status === Loader.Ready && previewLoader.item && previewLoader.item.hasOwnProperty("targetX")
                        }
                        Binding {
                            target: previewLoader.item
                            property: "targetY"
                            value: previewLoader.mapFromItem(null, root._cursorWindowX, root._cursorWindowY).y
                            when: previewLoader.isWeyes && previewLoader.status === Loader.Ready && previewLoader.item && previewLoader.item.hasOwnProperty("targetY")
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: tile.modelData.icon
                        iconSize: 26
                        color: Colors.md3.on_surface_variant
                        visible: !tile.available
                    }
                }

                Column {
                    id: labelCol
                    anchors {
                        top: previewPane.bottom
                        topMargin: 5
                        left: parent.left
                        right: parent.right
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 1

                    Text {
                        width: parent.width
                        text: tile.modelData.label
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            if (!tile.available)
                                return Localization.t("widgetDrawer.unavailable");
                            if (tile.modelData.stackable)
                                return Localization.t("widgetDrawer.add");
                            return tile.present ? Localization.t("widgetDrawer.remove") : Localization.t("widgetDrawer.add");
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 9
                        color: tile.present ? Colors.md3.primary : Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 4
                    }
                    width: 18
                    height: 18
                    radius: 9
                    color: Colors.md3.primary
                    visible: tile.present && tile.modelData.stackable

                    Text {
                        anchors.centerIn: parent
                        text: tile.count
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Colors.md3.on_primary
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: tile.interactive
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(tile.modelData)
                }
            }
        }
    }
}
