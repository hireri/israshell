pragma ComponentBehavior: Bound

import QtQuick
import "markup.js" as Markup

Item {
    id: root

    property var shapes: []
    property var draft: null
    property real originX: 0
    property real originY: 0
    property Item backgroundSource: null
    property int hiddenIndex: -1

    function onLayer(s) {
        if (!s)
            return false;
        const b = Markup.bounds(s);
        return b.x + b.w >= originX && b.x <= originX + width && b.y + b.h >= originY && b.y <= originY + height;
    }

    Repeater {
        model: root.shapes
        delegate: MarkupShape {
            required property var modelData
            required property int index
            shape: modelData
            z: Markup.isEffect(modelData.type) ? 0 : 1
            originX: root.originX
            originY: root.originY
            backgroundSource: root.backgroundSource
            visible: index !== root.hiddenIndex && root.onLayer(modelData)
            anchors.fill: parent
        }
    }

    MarkupShape {
        shape: root.draft
        z: root.draft !== null && Markup.isEffect(root.draft.type) ? 0 : 1
        visible: root.onLayer(root.draft)
        originX: root.originX
        originY: root.originY
        backgroundSource: root.backgroundSource
        anchors.fill: parent
    }
}
