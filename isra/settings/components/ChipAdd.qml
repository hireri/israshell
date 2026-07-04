import QtQuick
import QtQuick.Controls.Basic
import qs.style

Item {
    id: root

    property string placeholder: "Add..."
    property int maxFieldWidth: 160
    signal confirmed(string value)

    property bool editing: false

    implicitHeight: 32
    implicitWidth: editing
        ? (fieldRow.implicitWidth + 24)
        : (idleLabel.implicitWidth + 24)

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.editing ? Colors.md3.surface_container_high : Colors.md3.surface_container
        border.width: root.editing ? 1.5 : 1
        border.color: root.editing ? Colors.md3.primary : Colors.md3.outline_variant

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        id: idleLabel
        anchors.centerIn: parent
        text: "+ Add"
        font.family: Config.fontFamily
        font.pixelSize: 12
        color: Colors.md3.on_surface_variant
        visible: opacity > 0
        opacity: root.editing ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        visible: !root.editing
        enabled: !root.editing
        onClicked: {
            root.editing = true;
            field.forceActiveFocus();
        }
    }

    Row {
        id: fieldRow
        anchors.centerIn: parent
        spacing: 6
        visible: opacity > 0
        opacity: root.editing ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        TextField {
            id: field
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.maxFieldWidth, Math.max(60, implicitWidth))
            topPadding: 0
            bottomPadding: 0
            leftPadding: 4
            rightPadding: 4
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.on_surface
            placeholderTextColor: Colors.md3.outline
            placeholderText: root.placeholder
            background: null

            Keys.onReturnPressed: root._commit()
            Keys.onEscapePressed: root._cancel()
            onActiveFocusChanged: {
                if (!activeFocus && root.editing) {
                    blurCancelTimer.start();
                }
            }
        }

        Item {
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            opacity: field.text.trim().length > 0 ? 1 : 0.35

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "\u2713"
                font.pixelSize: 13
                color: Colors.md3.primary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: field.text.trim().length > 0
                onClicked: root._commit()
            }
        }
    }

    Timer {
        id: blurCancelTimer
        interval: 80
        onTriggered: {
            if (!field.activeFocus)
                root._cancel();
        }
    }

    function _commit() {
        const val = field.text.trim();
        if (val.length > 0) {
            root.confirmed(val);
        }
        _cancel();
    }

    function _cancel() {
        field.text = "";
        root.editing = false;
    }
}
