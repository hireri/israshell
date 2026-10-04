import QtQuick
import QtQuick.Controls.Basic
import qs.style

Rectangle {
    id: root

    property string text
    property string placeholder
    property bool commitOnReturn: true
    property int fontSize: 12
    property bool flat: false

    signal edited(string text)
    signal committed(string text)

    radius: root.flat ? 16 : 8
    color: root.flat ? Colors.md3.surface_container_high : Config.dim(Colors.md3.surface_container)
    border.width: field.activeFocus ? 1.5 : root.flat ? 0 : 1
    border.color: field.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: root.flat ? 12 : 8
        contentWidth: width
        contentHeight: field.implicitHeight
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        TextArea {
            id: field
            width: parent.width
            text: root.text
            placeholderText: root.placeholder
            wrapMode: TextArea.Wrap
            font.family: root.flat ? Config.fontFamily : Config.fontMonospace
            font.pixelSize: root.fontSize
            color: Colors.md3.on_surface
            placeholderTextColor: Colors.md3.outline
            selectByMouse: true
            background: Item {}

            onTextChanged: {
                if (activeFocus)
                    root.edited(text);
            }

            Keys.onEscapePressed: {
                if (root.commitOnReturn)
                    text = root.text;
                focus = false;
            }

            Keys.onReturnPressed: event => {
                if (root.commitOnReturn && !(event.modifiers & Qt.ShiftModifier)) {
                    root.committed(text);
                    focus = false;
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }

            onFocusChanged: {
                if (!focus)
                    root.committed(text);
            }
        }
    }
}
