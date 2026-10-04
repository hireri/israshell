import QtQuick

SettingRow {
    id: root

    default property alias buttons: actions.data

    Row {
        id: actions
        spacing: 8
    }
}
