import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.icons

Item {
    id: root

    property string query: ""
    readonly property bool hasResult: true

    signal copyResult(string text)

    property int _length: 16
    property bool _pin: false
    property string _password: ""

    onQueryChanged: _generate()

    function _generate() {
        const q = query.trim().toLowerCase();
        let len = 16;
        let isPin = false;

        const lenMatch = /\b\d+\b/.exec(q);
        if (lenMatch) {
            const parsedLen = parseInt(lenMatch[0]);
            if (parsedLen > 0 && parsedLen <= 128) {
                len = parsedLen;
            }
        }

        if (q.includes("pin") || q.includes("num")) {
            isPin = true;
            if (!lenMatch) len = 4;
        }

        root._length = len;
        root._pin = isPin;

        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?";
        if (isPin) {
            chars = "0123456789";
        } else if (q.includes("easy") || q.includes("simple")) {
            chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        }

        let pass = "";
        for (let i = 0; i < len; i++) {
            const idx = Math.floor(Math.random() * chars.length);
            pass += chars.charAt(idx);
        }
        root._password = pass;
    }

    implicitHeight: 52

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: (root._pin ? "PIN" : "PASSWORD") + "  ·  " + root._length + " chars"
                color: Colors.md3.primary
                font.pixelSize: 10
                font.family: Config.fontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                text: root._password
                color: Colors.md3.on_surface
                font.pixelSize: root._length > 24 ? 14 : 18
                font.family: "JetBrains Mono"
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: regBtn
                width: 32
                height: 32
                radius: 16
                color: regMa.containsMouse ? Colors.md3.surface_container_high : "transparent"
                
                MaterialIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    iconSize: 18
                    color: Colors.md3.on_surface_variant
                }

                MouseArea {
                    id: regMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._generate()
                }
            }

            Rectangle {
                id: copyBtn
                width: 56
                height: 32
                radius: 16
                color: copyMa.containsMouse ? Colors.md3.primary : Colors.md3.primary_container

                Text {
                    anchors.centerIn: parent
                    text: "Copy"
                    color: copyMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: copyMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyResult(root._password)
                }
            }
        }
    }
}