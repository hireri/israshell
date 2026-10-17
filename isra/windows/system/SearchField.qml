import QtQuick
import qs.style
import qs.icons

Rectangle {
    id: root

    property string placeholder: ""
    readonly property string text: input.text
    property string query: ""

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.text = "";
    }

    height: 36
    radius: 18
    color: Config.dim(Colors.md3.surface_container)

    Row {
        anchors {
            left: parent.left
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 6
        opacity: input.text.length === 0 ? 0.5 : 0

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            iconSize: 15
            color: Colors.md3.on_surface_variant
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Colors.md3.on_surface_variant
        }
    }

    TextInput {
        id: input
        anchors {
            left: parent.left
            leftMargin: 14
            right: clearButton.left
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        font.family: Config.fontFamily
        font.pixelSize: 13
        color: Colors.md3.on_surface
        selectionColor: Qt.alpha(Colors.md3.primary, 0.3)
        selectedTextColor: Colors.md3.on_surface
        clip: true

        onTextChanged: {
            if (text === "") {
                debounce.stop();
                root.query = "";
            } else {
                debounce.restart();
            }
        }

        Keys.onEscapePressed: {
            text = "";
            focus = false;
        }

        Timer {
            id: debounce
            interval: 150
            onTriggered: root.query = input.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.NoButton
        }
    }

    Rectangle {
        id: clearButton
        anchors {
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        width: 20
        height: 20
        radius: 10
        opacity: input.text.length > 0 ? 1 : 0
        visible: opacity > 0
        color: clearArea.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.18) : "transparent"

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: "close"
            iconSize: 12
            color: Colors.md3.on_surface_variant
        }

        MouseArea {
            id: clearArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clear();
                root.focusInput();
            }
        }
    }
}
