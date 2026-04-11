import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal copyResult(string text)

    implicitHeight: col.implicitHeight

    readonly property string _mode: {
        const q = query.trim();
        if (/^\d{9,11}$/.test(q))
            return "unix";
        if (/^(?:days?\s+(?:until|since|to|from)|time\s+since|how\s+long\s+(?:since|ago))/i.test(q))
            return "days";
        return "";
    }

    readonly property var _unixDate: {
        if (_mode !== "unix")
            return null;
        const d = new Date(parseInt(query.trim()) * 1000);
        return isNaN(d.getTime()) ? null : d;
    }

    readonly property string _longDate: {
        if (!_unixDate)
            return "";
        return _unixDate.toLocaleDateString("en-GB", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric"
        });
    }

    readonly property string _time: {
        if (!_unixDate)
            return "";
        return _unixDate.toLocaleTimeString("en-GB", {
            hour12: false
        });
    }

    readonly property string _relative: {
        if (!_unixDate)
            return "";
        return _humanRelative(_unixDate.getTime() / 1000);
    }

    readonly property string _isoString: {
        if (!_unixDate)
            return "";
        return _unixDate.toISOString();
    }

    function _humanRelative(ts) {
        const diff = Date.now() / 1000 - ts;
        const abs = Math.abs(diff);
        const past = diff > 0;
        const fmt = (n, unit) => past ? n + " " + unit + (n !== 1 ? "s" : "") + " ago" : "in " + n + " " + unit + (n !== 1 ? "s" : "");
        if (abs < 60)
            return past ? "just now" : "in a moment";
        if (abs < 3600)
            return fmt(Math.round(abs / 60), "minute");
        if (abs < 86400)
            return fmt(Math.round(abs / 3600), "hour");
        if (abs < 86400 * 30)
            return fmt(Math.round(abs / 86400), "day");
        if (abs < 86400 * 335)
            return fmt(Math.min(Math.round(abs / 2592000), 11), "month");
        return fmt(Math.round(abs / 31536000), "year");
    }

    readonly property var _daysResult: {
        if (_mode !== "days")
            return null;
        const q = query.trim();

        const m = /^(?:days?\s+|time\s+since\s+|how\s+long\s+since\s+|how\s+long\s+ago\s+)(until|to|since|from|)\s*(.+)$/i.exec(q);
        if (!m)
            return null;

        const rawDir = m[1].toLowerCase();
        const direction = /until|to/.test(rawDir) ? "until" : "since";
        const targetStr = m[2].trim();
        if (!targetStr)
            return null;

        const aliases = {
            "christmas": () => {
                const d = new Date();
                d.setMonth(11, 25);
                if (d < new Date())
                    d.setFullYear(d.getFullYear() + 1);
                return d;
            },
            "new year": () => {
                const d = new Date();
                d.setMonth(0, 1);
                if (d < new Date())
                    d.setFullYear(d.getFullYear() + 1);
                return d;
            },
            "halloween": () => {
                const d = new Date();
                d.setMonth(9, 31);
                if (d < new Date())
                    d.setFullYear(d.getFullYear() + 1);
                return d;
            },
            "valentine": () => {
                const d = new Date();
                d.setMonth(1, 14);
                if (d < new Date())
                    d.setFullYear(d.getFullYear() + 1);
                return d;
            },
            "valentines day": () => {
                const d = new Date();
                d.setMonth(1, 14);
                if (d < new Date())
                    d.setFullYear(d.getFullYear() + 1);
                return d;
            }
        };

        let target = null;
        for (const key in aliases) {
            if (targetStr.toLowerCase().startsWith(key)) {
                target = aliases[key]();
                break;
            }
        }
        if (!target)
            target = new Date(targetStr);
        if (isNaN(target.getTime()))
            return null;

        const diffMs = target - Date.now();
        const days = Math.round(Math.abs(diffMs) / 86400000);
        const past = diffMs < 0;

        return {
            days,
            past,
            direction,
            label: targetStr,
            targetDate: target.toLocaleDateString("en-GB", {
                year: "numeric",
                month: "long",
                day: "numeric"
            })
        };
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: false
        signal tapped

        implicitWidth: lbl.implicitWidth + 22
        implicitHeight: 30
        radius: height / 2
        color: ma.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Colors.md3.surface_container_high)
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
        spacing: 10

        Item {
            visible: root._mode === "unix" && root._unixDate !== null
            Layout.fillWidth: true
            implicitHeight: unixCol.implicitHeight

            ColumnLayout {
                id: unixCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                spacing: 2

                Text {
                    text: root._longDate
                    color: Colors.md3.on_surface
                    font.pixelSize: 26
                    font.weight: Font.Light
                    font.family: Config.fontFamily
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root._time
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 14
                        font.family: Config.fontFamily
                    }
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 2
                        color: Colors.md3.on_surface_variant
                        opacity: 0.35
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: root.query.trim() + " unix"
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        opacity: 0.45
                    }
                }

                Text {
                    text: root._relative
                    color: Colors.md3.primary
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    opacity: 0.8
                    topPadding: 2
                }
            }
        }

        Item {
            visible: root._mode === "days" && root._daysResult !== null
            Layout.fillWidth: true
            implicitHeight: daysCol.implicitHeight

            ColumnLayout {
                id: daysCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                spacing: 2

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: root._daysResult ? root._daysResult.days.toString() : ""
                        color: Colors.md3.on_surface
                        font.pixelSize: 46
                        font.weight: Font.Light
                        font.family: Config.fontFamily
                        lineHeight: 0.85
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4

                        Text {
                            text: "days"
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 15
                            font.family: Config.fontFamily
                        }
                        Text {
                            text: {
                                if (!root._daysResult)
                                    return "";
                                const d = root._daysResult;
                                return (d.past ? "since " : "until ") + d.label;
                            }
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            opacity: 0.55
                        }
                    }
                }

                Text {
                    visible: root._daysResult !== null
                    text: root._daysResult ? root._daysResult.targetDate : ""
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    opacity: 0.4
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                visible: root._mode === "unix" && root._unixDate !== null
                label: "󰆏  copy ISO"
                primary: true
                onTapped: root.copyResult(root._isoString)
            }
            PillBtn {
                visible: root._mode === "unix" && root._unixDate !== null
                label: "󰃭  copy date"
                onTapped: root.copyResult(root._longDate)
            }
            PillBtn {
                visible: root._mode === "unix" && root._unixDate !== null
                label: "  copy unix"
                onTapped: root.copyResult(root.query.trim())
            }

            PillBtn {
                visible: root._mode === "days" && root._daysResult !== null
                label: "󰃭  copy count"
                primary: true
                onTapped: root.copyResult(root._daysResult ? root._daysResult.days.toString() : "")
            }
            PillBtn {
                visible: root._mode === "days" && root._daysResult !== null
                label: "󰃭  copy date"
                onTapped: root.copyResult(root._daysResult ? root._daysResult.targetDate : "")
            }
        }
    }
}
