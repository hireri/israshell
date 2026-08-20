pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool active: false

    function toggle() {
        root.active = !root.active;
    }
}
