import QtQuick
import qs.style

SettingRow {
    id: root

    property var roles: ["primary", "secondary", "tertiary", "on_surface"]
    property string currentValue: ""
    property color fallback: Colors.md3.primary

    signal selected(string value)

    settingType: "chips"
    applySignal: "selected"

    stack: true

    ColorRoleStrip {
        width: root.contentWidth
        roles: root.roles
        selected: root.currentValue
        fallback: root.fallback
        onPicked: role => root.selected(role)
    }
}
