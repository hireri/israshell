import QtQuick
import qs.style
import qs.icons

Rectangle {
    id: root

    property string placeholder: ""
    property bool collapsed: false
    readonly property real collapsedWidth: 48
    readonly property real inset: 4
    readonly property string text: input.text
    property string query: ""

    signal toggled

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.text = "";
    }

    height: 40
    radius: 20
    color: Config.dim(Colors.md3.surface_container_high)
    clip: true

    Rectangle {
        id: toggleButton
        anchors {
            left: parent.left
            leftMargin: root.inset
            verticalCenter: parent.verticalCenter
        }
        width: root.collapsed ? root.collapsedWidth - 2 * root.inset : 32
        height: 32
        radius: 16

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        color: toggleArea.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.12) : Qt.alpha(Colors.md3.on_surface_variant, 0)

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: "menu"
            iconSize: 18
            color: Colors.md3.on_surface_variant
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    Item {
        anchors {
            left: toggleButton.right
            leftMargin: 8
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            text: root.placeholder
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Colors.md3.on_surface_variant
            opacity: input.text.length === 0 ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }

        TextInput {
            id: input
            anchors {
                left: parent.left
                right: clearButton.left
                rightMargin: 4
                verticalCenter: parent.verticalCenter
            }
            font.family: Config.fontFamily
            font.pixelSize: 14
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
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 24
            height: 24
            radius: 12
            opacity: input.text.length > 0 ? 1 : 0
            visible: opacity > 0
            color: clearArea.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.18) : Qt.alpha(Colors.md3.on_surface_variant, 0)

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "close"
                iconSize: 14
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
}
