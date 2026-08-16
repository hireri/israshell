pragma ComponentBehavior: Bound
import QtQuick
import qs.style

SettingRow {
    id: root
    property var options: []
    property var currentValue: null
    signal selected(var value)

    stack: root.compact

    SelectField {
        anchors.verticalCenter: root.stack ? undefined : parent?.verticalCenter
        width: root.stack ? root.contentWidth : implicitWidth
        options: root.options
        currentValue: root.currentValue
        onSelected: v => root.selected(v)
    }
}
