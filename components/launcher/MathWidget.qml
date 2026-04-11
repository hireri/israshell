import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    property bool hasResult: _result !== ""
    property string _result: ""

    signal copyResult(string result)
    signal swapRequested(string newQuery)

    readonly property bool isConversion: /[€$£¥₹₽₩₪]?[\d.,]+\s*[a-zA-Z°]+(?:\s+[a-zA-Z]+)?\s+(?:to|in)\s+[a-zA-Z]/i.test(query.trim())

    readonly property var _convFrom: {
        const m = /^[€$£¥₹₽₩₪]?([\d.,]+)\s*([a-zA-Z°]+(?:\s+[a-zA-Z]+)?)\s+(?:to|in)/i.exec(query.trim());
        if (!m)
            return {
                val: "",
                unit: ""
            };
        const unit = m[2].trim().replace(/\s+(?:to|in)$/i, "").trim();
        return {
            val: m[1],
            unit
        };
    }

    readonly property string _convToUnit: {
        const m = /(?:to|in)\s+(.+)$/i.exec(query.trim());
        return m ? m[1].trim() : "";
    }

    implicitHeight: isConversion ? conversionLayout.implicitHeight : mathLayout.implicitHeight

    onQueryChanged: {
        const q = query.trim();
        if (q === "" || !_looksLikeMath(q)) {
            _result = "";
            return;
        }
        debounce.restart();
    }

    function _looksLikeMath(q) {
        if (/^[€$£¥₹₽₩₪]/.test(q))
            return true;
        if (/\d/.test(q) || /[+\-*\/^%()]/.test(q))
            return true;
        return /\b(?:to|in|km|mile|kg|lb|oz|inch|foot|feet|meter|cm|mm|liter|gallon|celsius|fahrenheit|sqrt|sin|cos|tan|log|pi)\b/i.test(q);
    }

    function _cleanQuery(q) {
        const map = {
            "€": "eur",
            "$": "usd",
            "£": "gbp",
            "¥": "jpy",
            "₹": "inr",
            "₽": "rub",
            "₩": "krw",
            "₪": "ils"
        };
        const sym = q[0];
        const code = map[sym];
        if (!code)
            return q;
        const rest = q.slice(1).trim();
        if (new RegExp("\\b" + code + "\\b", "i").test(rest))
            return rest;
        return rest.replace(/^([\d.,]+)/, "$1 " + code);
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: {
            const q = root._cleanQuery(root.query.trim());
            if (!q || !root._looksLikeMath(q))
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
                root._result = (!out || out.toLowerCase() === root.query.trim().toLowerCase()) ? "" : out;
            }
        }
    }

    Process {
        id: openProc
        running: false
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: true
        signal clicked

        implicitWidth: pbLbl.implicitWidth + 22
        implicitHeight: 30
        radius: height / 2
        color: pbMa.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Colors.md3.surface_container_high)
        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        Text {
            id: pbLbl
            anchors.centerIn: parent
            text: pb.label
            color: pbMa.containsMouse ? (pb.primary ? Colors.md3.on_primary : Colors.md3.on_secondary_container) : (pb.primary ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant)
            font.pixelSize: 12
            font.family: Config.fontFamily
        }
        MouseArea {
            id: pbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }

    ColumnLayout {
        id: mathLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        visible: !root.isConversion
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: root.query
            color: Colors.md3.on_surface_variant
            font.pixelSize: 13
            font.family: Config.fontFamily
            opacity: 0.5
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root._result
            color: Colors.md3.on_surface
            font.pixelSize: 36
            font.weight: Font.Light
            font.family: Config.fontFamily
            elide: Text.ElideRight
            minimumPixelSize: 18
            fontSizeMode: Text.HorizontalFit
            lineHeight: 0.95
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.md3.outline_variant
            opacity: 0.4
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy result"
                primary: true
                onClicked: root.copyResult(root._result)
            }
            PillBtn {
                label: "󰆏  copy expression"
                primary: false
                onClicked: root.copyResult(root.query.trim())
            }
            PillBtn {
                label: "󰪚  open qalculate"
                primary: false
                onClicked: {
                    openProc.command = ["sh", "-c", "qalculate-gtk 2>/dev/null || kitty qalc 2>/dev/null &"];
                    openProc.running = true;
                }
            }
        }
    }

    ColumnLayout {
        id: conversionLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        visible: root.isConversion
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 14
                color: Colors.md3.surface_container_high

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 14
                    }
                    spacing: 3
                    Text {
                        text: "from"
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        opacity: 0.5
                        font.letterSpacing: 0.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._convFrom.val
                        color: Colors.md3.on_surface
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._convFrom.unit
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        opacity: 0.55
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                text: "→"
                color: Colors.md3.on_surface_variant
                font.pixelSize: 16
                opacity: 0.35
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 14
                color: Colors.md3.primary_container

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 14
                    }
                    spacing: 3
                    Text {
                        text: "to"
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        opacity: 0.55
                        font.letterSpacing: 0.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._result
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        minimumPixelSize: 14
                        fontSizeMode: Text.HorizontalFit
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._convToUnit
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        opacity: 0.65
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.md3.outline_variant
            opacity: 0.4
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy result"
                primary: true
                onClicked: root.copyResult(root._result)
            }
            PillBtn {
                label: "󰓡  swap"
                primary: false
                onClicked: {
                    if (root._result === "")
                        return;
                    root.swapRequested(root._result + " to " + root._convFrom.unit);
                }
            }
        }
    }
}
