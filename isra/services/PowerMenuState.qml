pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property bool visible: false

    onVisibleChanged: visible ? PanelService.opened(root) : PanelService.closed(root)

    function close() {
        visible = false;
    }

    function show() {
        visible = true;
    }
    function hide() {
        visible = false;
    }
    function toggle() {
        visible = !visible;
    }
}
