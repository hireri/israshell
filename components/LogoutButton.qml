import QtQuick
import Quickshell.Io
import qs.services

QtObject {
    id: button

    required property string command
    required property string text
    required property string icon
    property var keybind: null
    property color containerColor: "transparent"
    property color contentColor: "transparent"

    readonly property var process: Process {
        command: ["sh", "-c", button.command]
    }

    function exec() {
        PowerMenuState.hide();
        process.startDetached();
    }
}
