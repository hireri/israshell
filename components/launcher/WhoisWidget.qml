import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string subject: ""
    signal copyResult(string text)

    property bool _loading: false
    property bool _error: false
    property string _raw: ""
    property var _info: ({})

    readonly property bool _isIp: /^\d{1,3}(?:\.\d{1,3}){3}$/.test(subject.trim()) || /^[0-9a-fA-F:]{2,39}$/.test(subject.trim())

    implicitHeight: col.implicitHeight

    onSubjectChanged: {
        if (subject.trim() === "")
            return;
        _deb.restart();
    }

    Timer {
        id: _deb
        interval: 500
        onTriggered: {
            const s = root.subject.trim();
            if (!s)
                return;
            root._loading = true;
            root._error = false;
            root._raw = "";
            root._info = {};
            whoisProc.running = false;
            whoisProc.command = ["whois", s];
            whoisProc.running = true;
        }
    }

    Process {
        id: whoisProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._loading = false;
                if (this.text.trim() === "") {
                    root._error = true;
                    return;
                }
                root._raw = this.text;
                root._info = root._parse(this.text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "" && root._raw === "" && !root._loading)
                    root._error = true;
            }
        }
    }

    Process {
        id: browserProc
        running: false
    }

    function _parse(text) {
        const result = {};

        function get(patterns) {
            for (const p of patterns) {
                const re = new RegExp("^" + p + ":\\s*(.+)$", "im");
                const m = re.exec(text);
                if (m) {
                    const v = m[1].trim();
                    if (!v.startsWith("http") && v.length < 120)
                        return v;
                }
            }
            return null;
        }

        function fmtDate(raw) {
            if (!raw)
                return null;
            const clean = raw.split(/\s+/)[0];
            const d = new Date(clean);
            return isNaN(d.getTime()) ? raw : d.toLocaleDateString("en-GB", {
                year: "numeric",
                month: "short",
                day: "numeric"
            });
        }

        result.registrar = get(["Registrar", "registrar", "Sponsoring Registrar"]);
        result.created = fmtDate(get(["Creation Date", "Created", "Registered", "created", "Registration Time"]));
        result.expires = fmtDate(get(["Registry Expiry Date", "Expiry Date", "Expiration Date", "Registrar Registration Expiration Date", "expires", "Expiry"]));
        const statusRaw = get(["Domain Status", "Status", "status"]);
        if (statusRaw)
            result.status = statusRaw.split(/\s+/)[0];
        result.org = get(["OrgName", "Org-Name", "org-name", "Organization", "organization", "NetName", "netname", "descr"]);
        result.country = get(["Country", "country"]);
        result.range = get(["NetRange", "inetnum", "CIDR"]);

        return result;
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

    component InfoRow: RowLayout {
        property string label: ""
        property string value: ""
        visible: value !== "" && value !== null && value !== undefined
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: label
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
            font.family: Config.fontFamily
            opacity: 0.5
            Layout.preferredWidth: 80
        }
        Text {
            text: value ?? ""
            color: Colors.md3.on_surface
            font.pixelSize: 13
            font.family: Config.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: root.subject.trim()
                color: Colors.md3.on_surface
                font.pixelSize: 24
                font.weight: Font.Light
                font.family: Config.fontFamily
            }

            Rectangle {
                visible: !root._loading && (root._info.status ?? "") !== ""
                implicitWidth: stLbl.implicitWidth + 14
                height: 22
                radius: 11
                color: {
                    const s = (root._info.status ?? "").toLowerCase();
                    if (s.startsWith("active") || s.startsWith("ok"))
                        return Qt.rgba(39 / 255, 80 / 255, 10 / 255, 1);
                    if (s.startsWith("client") || s.startsWith("server"))
                        return Colors.md3.secondary_container;
                    return Colors.md3.surface_container_high;
                }

                Text {
                    id: stLbl
                    anchors.centerIn: parent
                    text: root._info.status ?? ""
                    color: {
                        const s = (root._info.status ?? "").toLowerCase();
                        if (s.startsWith("active") || s.startsWith("ok"))
                            return "#a8d578";
                        if (s.startsWith("client") || s.startsWith("server"))
                            return Colors.md3.on_secondary_container;
                        return Colors.md3.on_surface_variant;
                    }
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root._loading
                width: 6
                height: 6
                radius: 3
                color: Colors.md3.primary
                SequentialAnimation on opacity {
                    running: root._loading
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 600
                    }
                    NumberAnimation {
                        to: 0.9
                        duration: 600
                    }
                }
            }
        }

        Text {
            visible: root._error
            Layout.fillWidth: true
            text: "Whois lookup failed. Is `whois` installed?"
            color: Colors.md3.error
            font.pixelSize: 13
            font.family: Config.fontFamily
            opacity: 0.8
        }

        Item {
            visible: !root._loading && !root._error
            Layout.fillWidth: true
            implicitHeight: infoRows.implicitHeight

            ColumnLayout {
                id: infoRows
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.35
                }

                InfoRow {
                    label: "registrar"
                    value: root._info.registrar ?? ""
                }
                InfoRow {
                    label: "created"
                    value: root._info.created ?? ""
                }
                InfoRow {
                    label: "expires"
                    value: root._info.expires ?? ""
                }
                InfoRow {
                    label: "org"
                    value: root._info.org ?? ""
                }
                InfoRow {
                    label: "country"
                    value: root._info.country ?? ""
                }
                InfoRow {
                    label: "range"
                    value: root._info.range ?? ""
                }

                Text {
                    visible: !root._loading && !root._error && (root._info.registrar ?? "") === "" && (root._info.org ?? "") === "" && root._raw !== ""
                    Layout.fillWidth: true
                    text: "Data returned but format unrecognised. Copy raw for full output"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    font.italic: true
                    opacity: 0.5
                    wrapMode: Text.Wrap
                }
            }
        }

        Flow {
            visible: !root._loading && !root._error
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy " + (root._isIp ? "ip" : "domain")
                primary: true
                onTapped: root.copyResult(root.subject.trim())
            }
            PillBtn {
                label: "󰖟  open in browser"
                visible: !root._isIp
                onTapped: {
                    browserProc.command = ["xdg-open", "https://" + root.subject.trim()];
                    browserProc.running = true;
                }
            }
            PillBtn {
                label: "󰆏  copy raw"
                visible: root._raw !== ""
                onTapped: root.copyResult(root._raw)
            }
        }
    }
}
