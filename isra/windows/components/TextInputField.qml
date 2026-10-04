import QtQuick
import QtQuick.Controls.Basic
import qs.style

Rectangle {
    id: root

    property string text
    property string placeholder
    property bool password: false
    property alias validator: field.validator
    property alias inputMethodHints: field.inputMethodHints

    signal committed(string text)

    function commit() {
        root.committed(field.text);
    }

    function clear() {
        field.clear();
    }

    implicitWidth: 180
    implicitHeight: 36
    radius: 8
    color: Config.dim(Colors.md3.surface_container)
    border.width: field.activeFocus ? 1.5 : 1
    border.color: field.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    TextField {
        id: field
        anchors.fill: parent
        anchors.margins: 1
        text: root.text
        placeholderText: root.placeholder
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        font.family: root.password ? Config.fontFamily : Config.fontMonospace
        font.pixelSize: 12
        color: Colors.md3.on_surface
        placeholderTextColor: Colors.md3.outline
        leftPadding: 12
        rightPadding: 12
        background: Item {}

        Keys.onReturnPressed: {
            root.commit();
            focus = false;
        }
        Keys.onEscapePressed: {
            text = root.text;
            focus = false;
        }
        onFocusChanged: {
            if (!focus)
                root.commit();
        }
    }
}
