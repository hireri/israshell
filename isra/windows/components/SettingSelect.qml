pragma ComponentBehavior: Bound
import QtQuick
import qs.style

SettingRow {
    id: root
    property var options: []
    property var currentValue: null
    signal selected(var value)
    property bool isLast: false

    SelectField {
        anchors.verticalCenter: parent?.verticalCenter
        options: root.options
        currentValue: root.currentValue
        onSelected: v => root.selected(v)
    }
}
