import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    property bool hasResult: _valid

    signal copyResult(string text)

    property bool _valid: false
    property color _color: "transparent"
    property string _hex: ""
    property string _rgb: ""
    property string _hsl: ""

    onQueryChanged: _update(query.trim())

    function _update(str) {
        if (str === "") { _valid = false; return; }

        let c = Qt.color("transparent");
        let ok = false;

        if (/^#[0-9a-fA-F]{3,8}$/.test(str)) {
            c = Qt.color(str);
            ok = true;
        } else if (/^rgba?\s*\(/i.test(str)) {
            c = Qt.color(str);
            ok = c.a > 0 || /^rgba?\s*\(\s*0\s*,\s*0\s*,\s*0/i.test(str);
        } else if (/^hsl\s*\(/i.test(str)) {
            const m = /^hsl\s*\(\s*([\d.]+)\s*[,\s]\s*([\d.]+)%?\s*[,\s]\s*([\d.]+)%?\s*\)/i.exec(str);
            if (m) {
                c = Qt.hsla(parseFloat(m[1]) / 360, parseFloat(m[2]) / 100, parseFloat(m[3]) / 100, 1.0);
                ok = true;
            }
        }

        if (!ok) { _valid = false; return; }

        _color = c;
        _valid = true;

        const r = Math.round(c.r * 255);
        const g = Math.round(c.g * 255);
        const b = Math.round(c.b * 255);
        const a = Math.round(c.a * 255);

        const hex6 = r.toString(16).padStart(2, "0") +
                     g.toString(16).padStart(2, "0") +
                     b.toString(16).padStart(2, "0");
        _hex = "#" + hex6 + (a < 255 ? a.toString(16).padStart(2, "0") : "");
        _rgb = "rgb(" + r + ", " + g + ", " + b + ")";

        const rf = c.r, gf = c.g, bf = c.b;
        const mx = Math.max(rf, gf, bf), mn = Math.min(rf, gf, bf);
        const l = (mx + mn) / 2;
        let h = 0, s = 0;
        if (mx !== mn) {
            const d = mx - mn;
            s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
            if (mx === rf)      h = ((gf - bf) / d + (gf < bf ? 6 : 0)) / 6;
            else if (mx === gf) h = ((bf - rf) / d + 2) / 6;
            else                h = ((rf - gf) / d + 4) / 6;
        }
        _hsl = "hsl(" + Math.round(h * 360) + ", " + Math.round(s * 100) + "%, " + Math.round(l * 100) + "%)";
    }

    readonly property bool _isDark: (_color.r * 0.299 + _color.g * 0.587 + _color.b * 0.114) < 0.5

    implicitHeight: 138

    RowLayout {
        anchors.fill: parent
        spacing: 14

        Rectangle {
            width: 120
            Layout.fillHeight: true
            radius: 14
            color: root._valid ? root._color : Colors.md3.surface_container_high
            border.width: 1
            border.color: root._valid ? Qt.rgba(0, 0, 0, 0.15) : Colors.md3.outline_variant

            Text {
                anchors.centerIn: parent
                text: root._valid ? root._hex : "?"
                color: root._valid ? (root._isDark ? "white" : "black") : Colors.md3.on_surface_variant
                font.pixelSize: 12
                font.family: Config.fontFamily
                font.weight: Font.Medium
                opacity: root._valid ? 0.7 : 0.3
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Repeater {
                model: [
                    { label: "hex", value: root._hex },
                    { label: "rgb", value: root._rgb },
                    { label: "hsl", value: root._hsl }
                ]

                delegate: Item {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
                        spacing: 8

                        Text {
                            text: modelData.label
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 11
                            font.family: Config.fontFamily
                            opacity: 0.45
                            font.letterSpacing: 0.5
                            Layout.preferredWidth: 26
                        }

                        Text {
                            text: modelData.value
                            color: Colors.md3.on_surface
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: cpLbl.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: cpHov.containsMouse ? Colors.md3.primary_container : Colors.md3.surface_container_high
                            visible: root._valid
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                id: cpLbl
                                anchors.centerIn: parent
                                text: "copy"
                                color: cpHov.containsMouse ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                            }
                            MouseArea {
                                id: cpHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.copyResult(modelData.value)
                            }
                        }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 1
                        color: Colors.md3.outline_variant
                        opacity: 0.4
                        visible: index < 2
                    }
                }
            }
        }
    }
}
