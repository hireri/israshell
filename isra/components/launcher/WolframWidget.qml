pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services

Item {
    id: root

    property string question: ""

    readonly property string _appId: Secrets.get("wolfram")

    property string _answer: ""
    property bool _loading: false
    property bool _error: false
    property string _errorText: ""

    readonly property bool hasResult: question.trim() !== ""
    readonly property int answerLength: _answer.length

    readonly property int _answerFontSize: {
        const len = _answer.length;
        if (len <= 20)
            return 32;
        if (len <= 45)
            return 26;
        if (len <= 80)
            return 21;
        if (len <= 140)
            return 18;
        return 16;
    }

    signal copyResult(string text)

    implicitHeight: col.implicitHeight

    onQuestionChanged: {
        _answer = "";
        _error = false;
        _errorText = "";
        _deb.restart();
    }

    Timer {
        id: _deb
        interval: 1000
        onTriggered: {
            if (root.question.trim() === "")
                return;
            root._fetch();
        }
    }

    Timer {
        id: _retryTimer
        interval: 150
        onTriggered: {
            if (root.question.trim() !== "")
                root._fetch();
        }
    }

    function _fetch(): void {
        if (!Secrets.ready) {
            _retryTimer.restart();
            return;
        }
        if (root._appId === "") {
            root._loading = false;
            root._error = true;
            root._errorText = "No Wolfram key configured";
            return;
        }

        _loading = true;
        _error = false;
        _errorText = "";
        _answer = "";

        const url = "https://api.wolframalpha.com/v1/result?appid=" + encodeURIComponent(root._appId) + "&i=" + encodeURIComponent(root.question);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            _loading = false;

            if (xhr.status === 200) {
                root._answer = xhr.responseText.trim();
            } else if (xhr.status === 501) {
                root._error = true;
                root._errorText = "Couldn't interpret that";
            } else if (xhr.status === 403) {
                root._error = true;
                root._errorText = "Invalid or missing AppID";
            } else {
                root._error = true;
                root._errorText = "Request failed (" + xhr.status + ")";
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: true
        signal tapped

        implicitWidth: lbl.implicitWidth + 22
        implicitHeight: 30
        radius: height / 2
        color: ma.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        Text {
            id: lbl
            anchors.centerIn: parent
            text: pb.label
            color: ma.containsMouse ? (pb.primary ? Colors.md3.on_primary : Colors.md3.on_secondary_container) : (pb.primary ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant)
            font.pixelSize: 12
            font.family: Config.fontFamily
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.tapped()
        }
    }

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Colors.md3.primary
                visible: root._loading
                SequentialAnimation on opacity {
                    running: root._loading
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 450
                    }
                    NumberAnimation {
                        to: 0.9
                        duration: 450
                    }
                }
            }

            Text {
                visible: root._loading || (root._answer === "" && !root._error)
                text: root._loading ? "thinking..." : "..."
                color: Colors.md3.on_surface_variant
                font.pixelSize: root._loading ? 14 : 32
                font.weight: Font.Light
                font.family: Config.fontFamily
                opacity: 0.35
            }

            Text {
                id: answerText
                visible: !root._loading && (root._answer !== "" || root._error)
                Layout.fillWidth: true
                text: root._error ? (root._errorText !== "" ? root._errorText : "Query failed") : root._answer
                color: root._error ? Colors.md3.error : Colors.md3.on_surface
                font.pixelSize: root._error ? 18 : root._answerFontSize
                font.weight: Font.Light
                font.family: Config.fontFamily
                wrapMode: Text.Wrap
                lineHeight: 1.05
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root._answer !== "" && !root._error

            PillBtn {
                label: "󰆏  copy"
                primary: true
                onTapped: root.copyResult(root._answer)
            }
        }
    }
}
