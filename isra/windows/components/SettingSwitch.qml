import QtQuick
import qs.style

SettingRow {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    property bool isLast: false

    Md3Switch {
        checked: root.checked
        enabled: root.enabled
        onToggled: v => {
            root.checked = v;
            root.toggled(v);
        }
    }
}
