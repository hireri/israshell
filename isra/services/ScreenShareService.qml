pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var _videoSourceNodes: Pipewire.nodes.values.filter(n => (n.type & PwNodeType.VideoSource) === PwNodeType.VideoSource && n.properties?.["device.id"] === undefined)
    readonly property bool active: _videoSourceNodes.length > 0
}
