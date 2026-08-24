import QtQuick
import qs.services

Item {
    id: root

    required property var panelWindow
    property var controllerRegistry: null

    readonly property string panelType: "barMenu"
    readonly property real cardW: 190

    property bool isOpen: false
    property real cardX: 0

    function open(globalClickPos) {
        const sx = root.panelWindow.screen?.x ?? 0;
        const sw = root.panelWindow.screen?.width ?? 1920;
        cardX = Math.max(8, Math.min(globalClickPos.x - sx - root.cardW / 2, sw - root.cardW - 8));

        isOpen = true;
        PanelService.opened(root, root.panelWindow.screen);
    }

    function close() {
        if (!root.isOpen)
            return;
        isOpen = false;
        PanelService.closed(root);
    }

    Component.onCompleted: {
        if (root.controllerRegistry)
            root.controllerRegistry[root.panelType] = root;
    }
}
