import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.style

SettingRow {
    id: root

    property string value: "00:00"
    signal committed(string value)

    Component.onCompleted: _parse(root.value)
    onValueChanged: _parse(root.value)

    property int _hours: 0
    property int _minutes: 0

    function _parse(str) {
        const parts = str.split(":");
        if (parts.length !== 2)
            return;
        const h = parseInt(parts[0], 10);
        const m = parseInt(parts[1], 10);
        if (!isNaN(h))
            root._hours = Math.max(0, Math.min(23, h));
        if (!isNaN(m))
            root._minutes = Math.max(0, Math.min(59, m));
    }

    function _commit() {
        const str = String(root._hours).padStart(2, "0") + ":" + String(root._minutes).padStart(2, "0");
        root.committed(str);
    }

    function _nudgeHours(delta) {
        root._hours = ((root._hours + delta) % 24 + 24) % 24;
        _commit();
    }

    function _nudgeMinutes(delta) {
        root._minutes = ((root._minutes + delta) % 60 + 60) % 60;
        _commit();
    }

    Row {
        spacing: 2

        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            SpinButton {
                onClicked: root._nudgeHours(1)
                up: true
            }

            SpinField {
                value: root._hours
                max: 23
                onCommitted: v => {
                    root._hours = v;
                    root._commit();
                }
                onScrolled: delta => root._nudgeHours(delta)
            }

            SpinButton {
                onClicked: root._nudgeHours(-1)
                up: false
            }
        }

        Text {
            text: ":"
            font.family: Config.fontMonospace
            font.pixelSize: 15
            font.weight: Font.Medium
            color: Colors.md3.outline
            anchors.verticalCenter: parent.verticalCenter
            bottomPadding: 2
        }

        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            SpinButton {
                onClicked: root._nudgeMinutes(5)
                up: true
            }

            SpinField {
                value: root._minutes
                max: 59
                onCommitted: v => {
                    root._minutes = v;
                    root._commit();
                }
                onScrolled: delta => root._nudgeMinutes(delta * 5)
            }

            SpinButton {
                onClicked: root._nudgeMinutes(-5)
                up: false
            }
        }
    }

    component SpinField: Rectangle {
        property int value: 0
        property int max: 23
        signal committed(int value)
        signal scrolled(int delta)

        width: 28
        height: 28
        radius: 4
        color: field.activeFocus ? Colors.md3.surface_container_high : Colors.md3.surface_container
        Behavior on color {
            ColorAnimation {
                duration: 80
            }
        }

        TextInput {
            id: field
            anchors.centerIn: parent
            text: String(parent.value).padStart(2, "0")
            font.family: Config.fontMonospace
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Colors.md3.on_surface
            width: 24
            horizontalAlignment: TextInput.AlignHCenter
            maximumLength: 2
            inputMethodHints: Qt.ImhDigitsOnly
            selectByMouse: true

            onEditingFinished: {
                const v = parseInt(text, 10);
                if (!isNaN(v))
                    parent.committed(Math.max(0, Math.min(parent.max, v)));
                else
                    text = String(parent.value).padStart(2, "0");
            }

            onActiveFocusChanged: {
                if (!activeFocus)
                    text = String(parent.value).padStart(2, "0");
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                parent.scrolled(event.angleDelta.y > 0 ? 1 : -1);
            }
        }
    }

    component SpinButton: Rectangle {
        property bool up: true
        signal clicked

        width: 28
        height: 18
        radius: 4
        z: 1
        color: btnArea.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container
        Behavior on color {
            ColorAnimation {
                duration: 80
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.up ? "󰅃" : "󰅀"
            font.pixelSize: 12
            color: Colors.md3.outline
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
