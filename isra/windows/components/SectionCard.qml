import QtQuick
import qs.style

Column {
    id: root

    property string label: ""
    property bool compact: false
    spacing: 0

    property string sectionKey: ""
    readonly property bool settingsSection: true

    Text {
        text: root.label
        font.family: Config.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
        color: Colors.md3.primary
        font.letterSpacing: 0.7
        visible: root.label !== ""
        topPadding: 4
        bottomPadding: 6
        leftPadding: 2
    }

    Item {
        width: root.width
        height: cardColumn.height

        Item {
            id: backLayer
            anchors.fill: parent
        }

        Column {
            id: cardColumn
            width: parent.width
            spacing: 3
            onChildrenChanged: Qt.callLater(root._updateShape)
        }
    }

    default property alias items: cardColumn.data

    Component {
        id: backing

        Rectangle {
            required property Item target

            x: target.x
            y: target.y
            width: target.width
            height: target.height
            visible: target.visible
            color: Config.dim(Colors.md3.surface_container)

            Behavior on topLeftRadius {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Behavior on bottomLeftRadius {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }

    Component.onCompleted: Qt.callLater(_updateShape)

    property var _trackedRows: []
    property var _backs: new Map()

    function _updateShape() {
        const items = [];
        const kids = cardColumn.children;
        for (let i = 0; i < kids.length; i++) {
            const k = kids[i];
            if (typeof k.itemAt !== "function" && !k.hasOwnProperty("lineCount"))
                items.push(k);
        }

        for (const item of items) {
            if (root._trackedRows.indexOf(item) === -1) {
                root._trackedRows.push(item);
                item.visibleChanged.connect(() => Qt.callLater(root._updateShape));
            }
            if (root.compact && item.hasOwnProperty("compact"))
                item.compact = true;
        }

        const shown = items.filter(r => r.visible);
        for (let i = 0; i < shown.length; i++) {
            const item = shown[i];
            const top = i === 0 ? 18 : 6;
            const bottom = i === shown.length - 1 ? 18 : 6;
            if (item.hasOwnProperty("topRadius")) {
                item.topRadius = top;
                item.bottomRadius = bottom;
                continue;
            }
            let back = root._backs.get(item);
            if (!back) {
                back = backing.createObject(backLayer, { target: item });
                root._backs.set(item, back);
            }
            back.topLeftRadius = back.topRightRadius = top;
            back.bottomLeftRadius = back.bottomRightRadius = bottom;
        }
    }
}
