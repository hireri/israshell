import QtQuick
import Quickshell.Widgets
import qs.components
import qs.style

SettingRow {
    id: root

    property var options: []
    property var currentValue: null
    signal selected(var value)

    property Component icon: null

    settingType: "chips"
    applySignal: "selected"

    stack: root.compact

    Row {
        spacing: 10
        anchors.verticalCenter: root.stack ? undefined : parent?.verticalCenter

        Loader {
            active: root.icon !== null
            sourceComponent: root.icon
            anchors.verticalCenter: parent.verticalCenter
        }

        ChipRow {
            anchors.verticalCenter: parent.verticalCenter
            options: root.options
            currentValue: root.currentValue
            compact: root.compact
            onSelected: v => root.selected(v)
        }
    }
}
