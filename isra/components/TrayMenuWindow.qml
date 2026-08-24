import QtQuick
import qs.services

Item {
    id: root

    property var trayItem: null
    required property var panelWindow
    property var controllerRegistry: null

    readonly property string panelType: "trayMenu"
    readonly property real cardW: 210

    property var activeSubmenu: null
    property bool submenuOpen: false
    property bool isOpen: false

    property real cardX: 0

    function open(item, globalIconPos) {
        submenuOpen = false;
        activeSubmenu = null;
        trayItem = item;

        const sx = root.panelWindow.screen?.x ?? 0;
        const sw = root.panelWindow.screen?.width ?? 1920;
        cardX = Math.max(8, Math.min(globalIconPos.x - sx - root.cardW / 2, sw - root.cardW - 8));

        isOpen = true;
        PanelService.opened(root, root.panelWindow.screen);
    }

    function close() {
        closeAll();
    }

    function closeAll() {
        if (!root.isOpen)
            return;
        submenuOpen = false;
        activeSubmenu = null;
        isOpen = false;
        PanelService.closed(root);
    }

    function openSubmenu(entry) {
        activeSubmenu = entry;
        submenuOpen = true;
    }

    function goBack() {
        submenuOpen = false;
        activeSubmenu = null;
    }

    Component.onCompleted: {
        if (root.controllerRegistry)
            root.controllerRegistry[root.panelType] = root;
    }
}
