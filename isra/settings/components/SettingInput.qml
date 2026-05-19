import QtQuick
import QtQuick.Controls.Basic
import qs.style

SettingRow {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool password: false
    property int fieldWidth: 180
    property bool isLast: false

    signal committed(string value)

    Rectangle {
        implicitWidth: root.fieldWidth
        implicitHeight: 36
        anchors.verticalCenter: parent?.verticalCenter
        radius: 8
        color: Colors.md3.surface_container
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
            text: root.value
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
                root.committed(field.text);
                focus = false;
            }
            Keys.onEscapePressed: {
                text = root.value;
                focus = false;
            }
            onFocusChanged: if (!focus)
                root.committed(field.text)
        }
    }
}
