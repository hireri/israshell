import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.style

Item {
    id: root

    property string label: ""
    property string sublabel: ""
    property string value: ""
    property string placeholder: ""
    property int areaHeight: 90
    property bool isLast: false

    default property alias trailing: trailingSlot.data

    signal committed(string value)

    implicitWidth: parent?.width ?? 0
    implicitHeight: column.implicitHeight + 20

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        height: 1
        color: Colors.md3.outline_variant
        visible: !root.isLast
        opacity: 0.5
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 18
            rightMargin: 18
            topMargin: 10
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: root.label !== "" || root.sublabel !== ""

                Text {
                    text: root.label
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Colors.md3.on_surface
                    Layout.fillWidth: true
                    visible: root.label !== ""
                    elide: Text.ElideRight
                }

                Text {
                    text: root.sublabel
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    visible: root.sublabel !== ""
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                id: trailingSlot
                Layout.alignment: Qt.AlignTop
                spacing: 8
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.areaHeight
            radius: 8
            color: (Config.dim(Colors.md3.surface_container))
            border.width: field.activeFocus ? 1.5 : 1
            border.color: field.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentWidth: width
                contentHeight: field.implicitHeight
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                TextArea {
                    id: field
                    width: parent.width
                    text: root.value
                    placeholderText: root.placeholder
                    wrapMode: TextArea.Wrap
                    font.family: Config.fontMonospace
                    font.pixelSize: 12
                    color: Colors.md3.on_surface
                    placeholderTextColor: Colors.md3.outline
                    selectByMouse: true
                    background: Item {}

                    Keys.onEscapePressed: {
                        text = root.value;
                        focus = false;
                    }
                    Keys.onReturnPressed: event => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            event.accepted = false;
                        } else {
                            root.committed(text);
                            focus = false;
                            event.accepted = true;
                        }
                    }
                    onFocusChanged: if (!focus)
                        root.committed(text)
                }
            }
        }
    }
}
