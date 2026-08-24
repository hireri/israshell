import QtQuick
import qs.services

Item {
    id: root

    required property var panelWindow
    property var registry: null
    property var controllerRegistry: null

    readonly property string panelType: "wallpaper"

    readonly property bool isOpen: WallpaperService.isOpen && WallpaperService.openWindow === root.panelWindow

    function toggleSelf(): void {
        WallpaperService.toggleFor(root.panelWindow);
    }

    function close(): void {
        if (root.isOpen)
            WallpaperService.close();
    }

    onIsOpenChanged: {
        if (isOpen) {
            PanelService.opened(root, root.panelWindow.screen);
        } else {
            PanelService.closed(root);
        }
    }

    Component.onCompleted: Qt.callLater(() => {
        PanelService.register(root, root.controllerRegistry, root.registry, root.panelWindow?.screen?.name ?? "");
    })
}
