import QtQuick
import qs.style
import qs.services

SettingRow {
    id: root

    property bool checked: false
    property string previewSound: ""
    signal toggled(bool checked)

    settingType: "switch"
    applySignal: "toggled"

    ActionButton {
        visible: root.previewSound !== ""
        anchors.verticalCenter: parent.verticalCenter
        icon: "volume-up"
        enabled: root.enabled
        onClicked: SoundService.play(root.previewSound, true)
    }

    Md3Switch {
        checked: root.checked
        enabled: root.enabled
        onToggled: v => root.toggled(v)
    }
}
