import QtQuick
import QtQuick.Controls.Basic
import qs.style

Rectangle {
    id: root

    property string text
    property string placeholder
    property bool password: false
    property bool monospace: true
    property int fontSize: 12
    property int hPadding: 12
    property alias validator: field.validator
    property alias inputMethodHints: field.inputMethodHints

    signal committed(string text)
    signal edited(string text)
    signal accepted
    signal escaped

    function commit() {
        root.committed(field.text);
    }

    function focusField() {
        field.forceActiveFocus();
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
        font.family: root.password || !root.monospace ? Config.fontFamily : Config.fontMonospace
        font.pixelSize: root.fontSize
        color: Colors.md3.on_surface
        placeholderTextColor: Colors.md3.outline
        leftPadding: root.hPadding
        rightPadding: root.hPadding
        background: Item {}

        onTextChanged: root.edited(text)

        Keys.onReturnPressed: {
            root.accepted();
            root.commit();
            focus = false;
        }
        Keys.onEscapePressed: {
            text = root.text;
            root.escaped();
            focus = false;
        }
        onFocusChanged: {
            if (!focus)
                root.commit();
        }
    }
}
