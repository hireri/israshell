pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.components
import "../../services/skintone.js" as SkinTone

Item {
    id: root

    property var model
    property int skinToneIndex: 0
    property int current: -1
    readonly property int count: grid.count
    readonly property real contentHeight: Math.ceil(grid.count / columns) * 52 + 8
    readonly property int columns: Math.max(1, Math.floor(width / 52))

    signal itemActivated(var entry)

    function _entry(i) {
        return root.model?.values[i] ?? null;
    }

    function _select(i) {
        if (i < 0 || i >= grid.count)
            return;
        current = i;
        grid.positionViewAtIndex(i, GridView.Contain);
    }

    function resetToTop() {
        current = grid.count > 0 ? 0 : -1;
        grid.positionViewAtBeginning();
        Qt.callLater(cursor.snap);
    }
    function moveUp() {
        _select(Math.max(0, current - columns));
    }
    function moveDown() {
        _select(Math.min(grid.count - 1, current + columns));
    }
    function moveLeft() {
        _select(Math.max(0, current - 1));
    }
    function moveRight() {
        _select(Math.min(grid.count - 1, current + 1));
    }
    function pageUp() {
        _select(Math.max(0, current - columns * 4));
    }
    function pageDown() {
        _select(Math.min(grid.count - 1, current + columns * 4));
    }
    function activateCurrent() {
        const e = _entry(current);
        if (e)
            root.itemActivated(_tone(e));
    }

    function _tone(entry) {
        return Object.assign({}, entry, { emoji: SkinTone.applySkinTone(entry.emoji, root.skinToneIndex) });
    }

    Connections {
        target: root.model || null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            Qt.callLater(root.resetToTop);
        }
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: 4
        model: root.model?.values ?? []
        clip: true
        cellWidth: Math.floor(width / root.columns)
        cellHeight: 52
        currentIndex: -1
        highlightFollowsCurrentItem: false
        boundsBehavior: Flickable.DragAndOvershootBounds
        onCountChanged: root.resetToTop()

        Rectangle {
            id: cursor
            parent: grid.contentItem
            z: -1

            property bool _ready: false
            readonly property real _tx: (root.current % root.columns) * grid.cellWidth + 2
            readonly property real _ty: Math.floor(root.current / root.columns) * grid.cellHeight + 2
            function snap() {
                _ready = false;
                x = Qt.binding(() => cursor._tx);
                y = Qt.binding(() => cursor._ty);
                _ready = true;
            }

            x: _tx
            y: _ty
            width: grid.cellWidth - 4
            height: grid.cellHeight - 4
            radius: 16
            color: Colors.md3.secondary_container
            visible: root.current >= 0
            Component.onCompleted: snap()

            Behavior on x {
                enabled: cursor._ready
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                enabled: cursor._ready
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight

            Text {
                anchors.centerIn: parent
                text: SkinTone.applySkinTone(cell.modelData.emoji ?? "", root.skinToneIndex)
                font.pixelSize: 26
                font.family: Config.fontFamily
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = cell.index
                onClicked: root.itemActivated(root._tone(cell.modelData))
            }

            Tooltip {
                text: cell.modelData.name ?? ""
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: Localization.t("launcher.no_emoji_found")
        color: Colors.md3.on_surface_variant
        font.pixelSize: 14
        font.family: Config.fontFamily
    }
}
