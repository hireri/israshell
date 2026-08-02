pragma ComponentBehavior: Bound

import QtQuick
import qs.style
import qs.services

Item {
    id: root

    readonly property var removedIds: Config.quickSettingsTiles?.removed ?? []

    implicitHeight: flow.implicitHeight

    function _restore(tileId) {
        const removed = root.removedIds.filter(id => id !== tileId);
        const active = [...(Config.quickSettingsTiles?.active ?? []), { id: tileId, size: 50 }];
        Config.update({ quickSettingsTiles: Object.assign({}, Config.quickSettingsTiles, { active: active, removed: removed }) });
    }

    Flow {
        id: flow
        width: parent.width
        spacing: 8

        Repeater {
            model: root.removedIds

            delegate: QsTile {
                id: trayTile
                required property string modelData

                tileId: modelData
                size: 25
                editMode: true
                removedMode: true
                targetWidth: 68
                tileHeight: 64

                onRestoreRequested: root._restore(modelData)
            }
        }
    }
}
