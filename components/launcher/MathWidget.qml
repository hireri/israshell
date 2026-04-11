import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    property bool hasResult: _result !== ""
    property string _result: ""

    implicitHeight: 52

    onQueryChanged: {
        if (query.trim() === "") {
            _result = "";
            return;
        }
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            const q = root.query.trim();
            if (q === "")
                return;
            mathProc.running = false;
            mathProc.command = ["qalc", "-t", q];
            mathProc.running = true;
        }
    }

    Process {
        id: mathProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                if (!out || out.toLowerCase() === root.query.trim().toLowerCase()) {
                    root._result = "";
                } else {
                    root._result = out;
                }
            }
        }
    }

    Process {
        id: copyProc
        running: false
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.md3.tertiary_container
        visible: root.hasResult

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 10

            Text {
                text: "󰪚"
                color: Colors.md3.on_tertiary_container
                font.pixelSize: 16
                font.family: Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.75
            }

            Text {
                text: root._result
                color: Colors.md3.on_tertiary_container
                font.pixelSize: 14
                font.family: Config.fontFamily
                font.bold: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }

            Text {
                text: "click to copy"
                color: Colors.md3.on_tertiary_container
                font.pixelSize: 10
                font.family: Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.55
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                copyProc.command = ["wl-copy", root._result];
                copyProc.running = true;
            }
        }
    }
}
