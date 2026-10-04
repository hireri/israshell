import QtQuick

SettingRow {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool password: false
    property int fieldWidth: 180
    property int fieldHeight: 36

    signal committed(string value)

    settingType: "input"
    applySignal: "committed"

    TextInputField {
        implicitWidth: root.fieldWidth
        implicitHeight: root.fieldHeight
        anchors.verticalCenter: parent?.verticalCenter
        text: root.value
        placeholder: root.placeholder
        password: root.password
        onCommitted: v => root.committed(v)
    }
}
