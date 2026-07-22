import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal copyResult(string text)

    implicitHeight: col.implicitHeight

    readonly property var _r: _compute(query)
    readonly property bool hasResult: _r.mode !== ""

    function _compute(q0) {
        const q = (q0 || "").trim();
        if (!q)
            return { mode: "" };

        if (/^\d{9,13}$/.test(q)) {
            const n = parseInt(q, 10);
            const ms = q.length >= 12 ? n : n * 1000;
            const d = new Date(ms);
            if (isNaN(d.getTime()))
                return { mode: "" };
            return _dateInfo(d, "unix", q);
        }

        const diffQ = _parseDiffQuery(q);
        if (diffQ) {
            const target = _resolveDate(diffQ.target);
            if (target) {
                const diffMs = target.getTime() - Date.now();
                const past = diffMs < 0;
                const value = _unitValue(Math.abs(diffMs), diffQ.unit);
                return {
                    mode: "diff",
                    value: value,
                    unit: diffQ.unit,
                    unitLabel: _unitLabel(diffQ.unit, value),
                    past: past,
                    label: diffQ.target,
                    targetDate: _formatLong(target),
                    targetIso: target.toISOString()
                };
            }
        }

        const resolved = _resolveDate(q);
        if (resolved)
            return _dateInfo(resolved, "date", q);

        return { mode: "" };
    }

    function _dateInfo(d, kind, raw) {
        return {
            mode: kind,
            longDate: _formatLong(d),
            time: d.toLocaleTimeString("en-GB", { hour12: false }),
            relative: _humanRelative(d.getTime() / 1000),
            iso: d.toISOString(),
            unix: Math.floor(d.getTime() / 1000).toString(),
            raw: raw
        };
    }

    function _formatLong(d) {
        return d.toLocaleDateString("en-GB", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric"
        });
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

    function _normalizeUnit(u) {
        const s = u.toLowerCase();
        if (s.startsWith("day")) return "days";
        if (s.startsWith("week")) return "weeks";
        if (s.startsWith("month")) return "months";
        if (s.startsWith("year")) return "years";
        if (s.startsWith("hour")) return "hours";
        if (s.startsWith("minute")) return "minutes";
        return "days";
    }

    function _unitLabel(unit, value) {
        const singular = unit.replace(/s$/, "");
        return Math.abs(value) === 1 ? singular : unit;
    }

    function _unitValue(absMs, unit) {
        const days = absMs / 86400000;
        switch (unit) {
            case "hours": return Math.round(absMs / 3600000);
            case "minutes": return Math.round(absMs / 60000);
            case "weeks": return Math.round(days / 7 * 10) / 10;
            case "months": return Math.round(days / 30.44 * 10) / 10;
            case "years": return Math.round(days / 365.25 * 10) / 10;
            default: return Math.round(days);
        }
    }

    function _parseDiffQuery(q) {
        let work = q;
        let unit = null;
        const um = /^(days?|weeks?|months?|years?|hours?|minutes?)\s+/i.exec(work);
        if (um) {
            unit = _normalizeUnit(um[1]);
            work = work.slice(um[0].length);
        }

        const patterns = [
            { re: /^until\s+(.+)$/i, dir: "until" },
            { re: /^to\s+(.+)$/i, dir: "until" },
            { re: /^since\s+(.+)$/i, dir: "since" },
            { re: /^from\s+(.+)$/i, dir: "until" }
        ];
        for (const p of patterns) {
            const m = p.re.exec(work.trim());
            if (m)
                return { unit: unit || "days", direction: p.dir, target: m[1].trim() };
        }

        const phrasePatterns = [
            { re: /^how\s+long\s+until\s+(.+)$/i, dir: "until" },
            { re: /^how\s+long\s+since\s+(.+)$/i, dir: "since" },
            { re: /^how\s+long\s+ago\s+(?:was\s+|is\s+)?(.+)$/i, dir: "since" },
            { re: /^time\s+since\s+(.+)$/i, dir: "since" },
            { re: /^time\s+until\s+(.+)$/i, dir: "until" }
        ];
        for (const p of phrasePatterns) {
            const m = p.re.exec(q.trim());
            if (m)
                return { unit: unit || "days", direction: p.dir, target: m[1].trim() };
        }

        return null;
    }

    function _resolveDate(str) {
        const s = str.trim();
        if (!s)
            return null;

        const alias = _resolveAlias(s);
        if (alias) return alias;

        const weekday = _resolveWeekday(s);
        if (weekday) return weekday;

        const offset = _resolveOffset(s);
        if (offset) return offset;

        const d = new Date(s);
        if (!isNaN(d.getTime())) return d;

        return null;
    }

    function _startOfDay(d) {
        const c = new Date(d);
        c.setHours(0, 0, 0, 0);
        return c;
    }

    function _resolveAlias(str) {
        const s = str.toLowerCase().trim();
        const now = new Date();
        const nextYearly = (month, day) => {
            const d = new Date(now.getFullYear(), month, day);
            if (root._startOfDay(d) < root._startOfDay(now))
                d.setFullYear(d.getFullYear() + 1);
            return d;
        };

        if (s === "today") return now;
        if (s === "tomorrow") { const d = new Date(now); d.setDate(d.getDate() + 1); return d; }
        if (s === "yesterday") { const d = new Date(now); d.setDate(d.getDate() - 1); return d; }
        if (s.startsWith("christmas")) return nextYearly(11, 25);
        if (s.startsWith("xmas")) return nextYearly(11, 25);
        if (s.startsWith("new year")) return nextYearly(0, 1);
        if (s.startsWith("halloween")) return nextYearly(9, 31);
        if (s.startsWith("valentine")) return nextYearly(1, 14);
        if (s.startsWith("thanksgiving")) {
            const fourthThursday = (year) => {
                let d = new Date(year, 10, 1);
                let count = 0;
                while (d.getMonth() === 10) {
                    if (d.getDay() === 4) {
                        count++;
                        if (count === 4) return d;
                    }
                    d.setDate(d.getDate() + 1);
                }
                return d;
            };
            let d = fourthThursday(now.getFullYear());
            if (root._startOfDay(d) < root._startOfDay(now))
                d = fourthThursday(now.getFullYear() + 1);
            return d;
        }
        return null;
    }

    readonly property var _weekdays: ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    function _resolveWeekday(str) {
        const m = /^(next|this|last)?\s*(sunday|monday|tuesday|wednesday|thursday|friday|saturday)$/i.exec(str.trim());
        if (!m)
            return null;

        const mod = (m[1] || "").toLowerCase();
        const targetIdx = root._weekdays.indexOf(m[2].toLowerCase());
        const now = new Date();
        const todayIdx = now.getDay();
        let diff = (targetIdx - todayIdx + 7) % 7;

        if (mod === "next")
            diff = diff === 0 ? 7 : diff + 7;
        else if (mod === "last")
            diff = diff === 0 ? -7 : diff - 7;

        const d = new Date(now);
        d.setDate(d.getDate() + diff);
        return d;
    }

    function _resolveOffset(str) {
        const m = /^(?:in\s+)?(\d+)\s*(day|days|week|weeks|month|months|year|years|hour|hours|minute|minutes)\s*(ago|from\s+now)?$/i.exec(str.trim());
        if (!m)
            return null;

        const n = parseInt(m[1], 10);
        const unit = root._normalizeUnit(m[2]);
        const isAgo = /ago/i.test(m[3] || "");
        const sign = isAgo ? -1 : 1;
        const d = new Date();

        switch (unit) {
            case "days": d.setDate(d.getDate() + sign * n); break;
            case "weeks": d.setDate(d.getDate() + sign * n * 7); break;
            case "months": d.setMonth(d.getMonth() + sign * n); break;
            case "years": d.setFullYear(d.getFullYear() + sign * n); break;
            case "hours": d.setHours(d.getHours() + sign * n); break;
            case "minutes": d.setMinutes(d.getMinutes() + sign * n); break;
        }
        return d;
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
            ColorAnimation { duration: 90 }
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
            visible: root._r.mode === "unix" || root._r.mode === "date"
            Layout.fillWidth: true
            implicitHeight: dateCol.implicitHeight

            ColumnLayout {
                id: dateCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                spacing: 2

                Text {
                    text: root._r.longDate || ""
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
                        text: root._r.time || ""
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 14
                        font.family: Config.fontFamily
                    }
                    Rectangle {
                        visible: root._r.mode === "unix"
                        width: 3
                        height: 3
                        radius: 2
                        color: Colors.md3.on_surface_variant
                        opacity: 0.35
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        visible: root._r.mode === "unix"
                        text: (root._r.raw || "") + " unix"
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        opacity: 0.45
                    }
                }

                Text {
                    text: root._r.relative || ""
                    color: Colors.md3.primary
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    opacity: 0.8
                    topPadding: 2
                }
            }
        }

        Item {
            visible: root._r.mode === "diff"
            Layout.fillWidth: true
            implicitHeight: diffCol.implicitHeight

            ColumnLayout {
                id: diffCol
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
                        text: root._r.mode === "diff" ? (Number.isInteger(root._r.value) ? root._r.value.toString() : root._r.value.toFixed(1)) : ""
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
                            text: root._r.mode === "diff" ? root._r.unitLabel : ""
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 15
                            font.family: Config.fontFamily
                        }
                        Text {
                            text: root._r.mode === "diff" ? ((root._r.past ? "since " : "until ") + root._r.label) : ""
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            opacity: 0.55
                        }
                    }
                }

                Text {
                    visible: root._r.mode === "diff"
                    text: root._r.mode === "diff" ? root._r.targetDate : ""
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
                visible: root._r.mode === "unix" || root._r.mode === "date"
                label: "󰆏  copy ISO"
                primary: true
                onTapped: root.copyResult(root._r.iso)
            }
            PillBtn {
                visible: root._r.mode === "unix" || root._r.mode === "date"
                label: "󰃭  copy date"
                onTapped: root.copyResult(root._r.longDate)
            }
            PillBtn {
                visible: root._r.mode === "unix" || root._r.mode === "date"
                label: "  copy unix"
                onTapped: root.copyResult(root._r.unix)
            }

            PillBtn {
                visible: root._r.mode === "diff"
                label: "󰃭  copy count"
                primary: true
                onTapped: root.copyResult(root._r.mode === "diff" ? (Number.isInteger(root._r.value) ? root._r.value.toString() : root._r.value.toFixed(1)) : "")
            }
            PillBtn {
                visible: root._r.mode === "diff"
                label: "󰃭  copy date"
                onTapped: root.copyResult(root._r.targetDate)
            }
            PillBtn {
                visible: root._r.mode === "diff"
                label: "  copy unix"
                onTapped: root.copyResult(root._r.targetIso ? Math.floor(new Date(root._r.targetIso).getTime() / 1000).toString() : "")
            }
        }
    }
}