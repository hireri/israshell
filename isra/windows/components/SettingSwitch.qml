import QtQuick
import qs.style

SettingRow {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    settingType: "switch"
    applySignal: "toggled"

    Md3Switch {
        checked: root.checked
        enabled: root.enabled
        onToggled: v => root.toggled(v)
    }
}
