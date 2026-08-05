import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons

SettingInput {
    id: secretRow
    required property string secretKey

    readonly property string _secretValue: Secrets.get(secretKey)
    readonly property bool _hasValue: _secretValue !== ""
    property bool _revealed: false

    value: _secretValue
    placeholder: _hasValue ? "" : "Not set"
    password: !_revealed
    fieldWidth: 200

    onCommitted: text => {
        if (text !== Secrets.get(secretRow.secretKey))
            Secrets.set(secretRow.secretKey, text);
        secretRow._revealed = false;
    }

    RowLayout {
        spacing: 4
        anchors.verticalCenter: parent?.verticalCenter

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            visible: secretRow._hasValue
            color: revealMa.containsMouse ? Colors.md3.secondary_container : "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                name: secretRow._revealed ? "visibility-off" : "visibility"
                iconSize: 17
                color: Colors.md3.on_surface_variant
            }

            MouseArea {
                id: revealMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: secretRow._revealed = !secretRow._revealed
            }
        }
    }
}