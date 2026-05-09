pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property bool visible: false

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
