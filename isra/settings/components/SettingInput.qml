import QtQuick
import QtQuick.Controls.Basic
import qs.style

SettingRow {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool password: false
    property int fieldWidth: 180
    signal committed(string value)

    property bool isLast: false

    TextField {
        id: field
        text: root.value
        placeholderText: root.placeholder
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        implicitWidth: root.fieldWidth
        implicitHeight: 36
        anchors.verticalCenter: parent?.verticalCenter

        font.family: root.password ? Config.fontFamily : Config.fontMonospace
        font.pixelSize: 12
        color: Colors.md3.on_surface
        placeholderTextColor: Colors.md3.outline
        leftPadding: 12
        rightPadding: 12

        background: Rectangle {
            radius: 8
            color: Colors.md3.surface_container_high
            border.width: field.activeFocus ? 1.5 : 1
            border.color: field.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        onEditingFinished: root.committed(field.text)
    }
}
