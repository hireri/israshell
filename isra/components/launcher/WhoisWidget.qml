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
    property string _errorMsg: ""
    property string _raw: ""
    property var _info: ({})

    readonly property bool _isIp: /^\d{1,3}(?:\.\d{1,3}){3}$/.test(subject.trim()) || /^[0-9a-fA-F:]{2,39}$/.test(subject.trim())
    readonly property bool _isAsn: /^AS\d+$/i.test(subject.trim())

    implicitHeight: col.implicitHeight

    onSubjectChanged: {
        if (subject.trim() === "")
            return;
        _info = {};
        _raw = "";
        _error = false;
        _errorMsg = "";
        _deb.restart();
    }

    Process {
        id: rdapProc

        property bool _stdoutDone: false
        property bool _stderrDone: false
        property int _exitCode: 0

        function checkComplete() {
            if (!_stdoutDone || !_stderrDone)
                return;

            root._loading = false;

            if (_exitCode !== 0 && !root._error && root._raw === "" && root._errorMsg === "") {
                root._error = true;
                root._errorMsg = "RDAP process failed (exit " + _exitCode + ")";
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                root._raw = output;
                rdapProc._stdoutDone = true;

                if (output === "") {} else if (output.includes("404") || output.includes("Not Found")) {
                    root._error = true;
                    root._errorMsg = "Domain/IP not found (404)";
                } else if (output.includes("400") || output.includes("Bad Request")) {
                    root._error = true;
                    root._errorMsg = "Invalid query format";
                } else if (output.includes("Rate limit") || output.includes("429")) {
                    root._error = true;
                    root._errorMsg = "Rate limited - try again later";
                } else {
                    root._info = root._parseText(output);
                    if (Object.keys(root._info).length === 0) {
                        root._error = true;
                        root._errorMsg = "Could not parse RDAP response";
                    }
                }

                rdapProc.checkComplete();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const err = this.text.trim();
                rdapProc._stderrDone = true;

                if (err !== "") {
                    root._error = true;
                    if (err.includes("command not found") || err.includes("No such file")) {
                        root._errorMsg = "RDAP not found. Install `rdap` from AUR";
                    } else {
                        root._errorMsg = err;
                    }
                }

                rdapProc.checkComplete();
            }
        }

        onExited: (exitCode, exitStatus) => {
            rdapProc._exitCode = exitCode;
            if (!rdapProc._stdoutDone)
                rdapProc._stdoutDone = true;
            if (!rdapProc._stderrDone)
                rdapProc._stderrDone = true;
            checkComplete();
        }

        onRunningChanged: {
            if (running) {
                _stdoutDone = false;
                _stderrDone = false;
                _exitCode = 0;
            }
        }
    }

    Timer {
        id: _deb
        interval: 500
        onTriggered: {
            const s = root.subject.trim();
            if (!s || s.length < 3)
                return;

            if (s.endsWith('.') || s.endsWith(':') || s.endsWith('-'))
                return;

            if (/^\d+\.\d*$/.test(s) || /^\d+\.\d+\.\d*$/.test(s))
                return;

            const looksLikeDomain = /^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$/.test(s) && s.includes('.');
            const looksLikeIP = /^[\d.:a-fA-F]+$/.test(s) && (s.includes('.') || s.includes(':'));
            const looksLikeASN = /^AS\d+$/i.test(s);

            if (!looksLikeDomain && !looksLikeIP && !looksLikeASN)
                return;

            root._loading = true;
            root._error = false;
            root._errorMsg = "";
            root._raw = "";
            root._info = {};
            rdapProc.running = false;
            rdapProc.command = ["rdap", s];
            rdapProc.running = true;
        }
    }

    Process {
        id: browserProc
        running: false
    }

    Process {
        id: copyProc
        running: false
    }

    function _parseText(text) {
        const result = {};
        const lines = text.split('\n');

        function getValue(pattern) {
            const re = new RegExp(`^${pattern}:\\s*(.+)$`, 'i');
            for (const line of lines) {
                const m = line.match(re);
                if (m)
                    return m[1].trim();
            }
            return null;
        }

        function getAllValues(pattern) {
            const re = new RegExp(`^${pattern}:\\s*(.+)$`, 'i');
            const values = [];
            for (const line of lines) {
                const m = line.match(re);
                if (m)
                    values.push(m[1].trim());
            }
            return values;
        }

        function fmtDate(raw) {
            if (!raw)
                return null;
            const d = new Date(raw);
            return isNaN(d.getTime()) ? raw : d.toLocaleDateString("en-GB", {
                year: "numeric",
                month: "short",
                day: "numeric"
            });
        }

        if (text.match(/Start Address:/i) || text.match(/^\d+\.\d+\.\d+\.\d+\s*-\s*\d+\.\d+\.\d+\.\d+/m)) {
            result.type = "ip";
            result.name = getValue("Name");
            result.handle = getValue("Handle");
            result.startAddress = getValue("Start Address");
            result.endAddress = getValue("End Address");
            result.ipVersion = getValue("IP Version");
            result.country = getValue("Country");
            result.cidr = getValue("CIDR");
            result.parent = getValue("Parent");
            result.port43 = getValue("Port43");
            result.assignmentType = getValue("Type");
            result.created = fmtDate(getValue("registration"));
            result.updated = fmtDate(getValue("last changed"));
            result.status = getValue("Status");

            let currentEntity = null;
            let currentRoles = [];

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                if (line.match(/^Entity Handle:/i)) {
                    currentEntity = line.match(/^Entity Handle:\s*(.+)$/i)?.[1]?.trim();
                    currentRoles = [];
                    continue;
                }

                const roleMatch = line.match(/^Role:\s*(.+)$/i);
                if (roleMatch) {
                    currentRoles.push(roleMatch[1].toLowerCase());
                    continue;
                }

                if (currentRoles.includes("abuse")) {
                    const emailMatch = line.match(/^Email:\s*(.+)$/i);
                    if (emailMatch && !result.abuseEmail) {
                        result.abuseEmail = emailMatch[1];
                    }
                    const nameMatch = line.match(/^Name:\s*(.+)$/i);
                    if (nameMatch && !result.abuseName) {
                        result.abuseName = nameMatch[1];
                    }
                }

                if (currentRoles.includes("registrant")) {
                    const orgMatch = line.match(/^Name:\s*(.+)$/i);
                    if (orgMatch && !result.registrantOrg) {
                        result.registrantOrg = orgMatch[1];
                    }
                }
            }
        } else if (text.includes("Object Class: domain") || text.match(/Domain Name:/i)) {
            result.type = "domain";

            result.name = getValue("Domain Name");
            result.handle = getValue("Handle");

            const statuses = getAllValues("Status");
            if (statuses.length > 0) {
                result.status = statuses[0].replace(/https:\/\/icann\.org\/epp#/, "");
                result.allStatuses = statuses;
            }

            const nsList = getAllValues("Nameserver");
            if (nsList.length > 0) {
                result.nameservers = nsList.join(", ");
            }

            const ds = getValue("Delegation Signed");
            if (ds) {
                result.dnssec = ds.toLowerCase() === "yes" ? "signed" : "unsigned";
            }

            result.created = fmtDate(getValue("Registration"));
            result.expires = fmtDate(getValue("Expiration") || getValue("registrar expiration"));
            result.updated = fmtDate(getValue("Last Changed"));
            result.rdapUpdated = fmtDate(getValue("Last Update"));

            result.port43 = getValue("Port43");

            let currentEntity = null;
            let currentRoles = [];

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                if (line.match(/^Entity Handle:/i)) {
                    currentEntity = line.match(/^Entity Handle:\s*(.+)$/i)?.[1]?.trim();
                    currentRoles = [];
                    continue;
                }

                const roleMatch = line.match(/^Role:\s*(.+)$/i);
                if (roleMatch) {
                    currentRoles.push(roleMatch[1].toLowerCase());
                    continue;
                }

                if (currentRoles.includes("registrar")) {
                    const idMatch = line.match(/^IANA Registrar ID:\s*(.+)$/i);
                    if (idMatch)
                        result.registrarId = idMatch[1];
                    const nameMatch = line.match(/^Name:\s*(.+)$/i);
                    if (nameMatch && !result.registrar)
                        result.registrar = nameMatch[1];
                }

                if (currentRoles.includes("registrant")) {
                    const orgMatch = line.match(/^Organization:\s*(.+)$/i);
                    if (orgMatch)
                        result.registrantOrg = orgMatch[1];
                    const nameMatch = line.match(/^Name:\s*(.+)$/i);
                    if (nameMatch && !result.registrantName)
                        result.registrantName = nameMatch[1];
                    const emailMatch = line.match(/^Email:\s*(.+)$/i);
                    if (emailMatch)
                        result.registrantEmail = emailMatch[1];
                }

                if (currentRoles.includes("abuse")) {
                    const emailMatch = line.match(/^Email:\s*(.+)$/i);
                    if (emailMatch && !result.abuseEmail) {
                        result.abuseEmail = emailMatch[1];
                    }
                }
            }
        } else if (text.includes("Object Class: autnum") || text.match(/autnum/i)) {
            result.type = "asn";
            result.asn = getValue("autnum") || getValue("Handle");
            result.name = getValue("Name");
            result.country = getValue("Country");
            result.handle = getValue("Handle");
        }

        if (text.includes("REDACTED FOR PRIVACY") || text.includes("REDACTED")) {
            result.redacted = true;
        }

        return result;
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: false
        property bool showBtn: true
        signal tapped

        implicitWidth: showBtn ? lbl.implicitWidth + 22 : 0
        implicitHeight: showBtn ? 30 : 0
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

        readonly property bool hasValue: value !== "" && value !== null && value !== undefined

        Layout.fillWidth: true
        spacing: 0

        Text {
            text: label
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
            font.family: Config.fontFamily
            opacity: 0.5
            Layout.preferredWidth: 80
            visible: parent.hasValue
        }
        Text {
            text: value ?? ""
            color: Colors.md3.on_surface
            font.pixelSize: 13
            font.family: Config.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: parent.hasValue
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

            Rectangle {
                visible: !root._loading && !root._error && (root._info.redacted ?? false)
                implicitWidth: redLbl.implicitWidth + 14
                height: 22
                radius: 11
                color: Colors.md3.tertiary_container

                Text {
                    id: redLbl
                    anchors.centerIn: parent
                    text: "redacted"
                    color: Colors.md3.on_tertiary_container
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
            visible: root._error && root._errorMsg !== ""
            Layout.fillWidth: true
            text: root._errorMsg
            color: Colors.md3.error
            font.pixelSize: 13
            font.family: Config.fontFamily
            opacity: 0.8
            wrapMode: Text.Wrap
        }

        Item {
            visible: !root._loading && !root._error && (root._info.type ?? "") === "domain"
            Layout.fillWidth: true
            implicitHeight: domainRows.implicitHeight

            ColumnLayout {
                id: domainRows
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
                    label: "registrar id"
                    value: root._info.registrarId ?? ""
                }
                InfoRow {
                    label: "created"
                    value: root._info.created ?? ""
                }
                InfoRow {
                    label: "updated"
                    value: root._info.updated ?? ""
                }
                InfoRow {
                    label: "expires"
                    value: root._info.expires ?? ""
                }
                InfoRow {
                    label: "nameservers"
                    value: root._info.nameservers ?? ""
                }
                InfoRow {
                    label: "dnssec"
                    value: root._info.dnssec ?? ""
                }
                InfoRow {
                    label: "registrant"
                    value: root._info.registrantOrg ?? root._info.registrantName ?? ""
                }
                InfoRow {
                    label: "abuse email"
                    value: root._info.abuseEmail ?? ""
                }
            }
        }

        Item {
            visible: !root._loading && !root._error && (root._info.type ?? "") === "ip"
            Layout.fillWidth: true
            implicitHeight: ipRows.implicitHeight

            ColumnLayout {
                id: ipRows
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
                    label: "network"
                    value: root._info.name ?? ""
                }
                InfoRow {
                    label: "handle"
                    value: root._info.handle ?? ""
                }
                InfoRow {
                    label: "range"
                    value: root._info.startAddress && root._info.endAddress ? `${root._info.startAddress} - ${root._info.endAddress}` : (root._info.cidr ?? "")
                }
                InfoRow {
                    label: "cidr"
                    value: root._info.cidr ?? ""
                }
                InfoRow {
                    label: "type"
                    value: root._info.assignmentType ?? ""
                }
                InfoRow {
                    label: "country"
                    value: root._info.country ?? ""
                }
                InfoRow {
                    label: "status"
                    value: root._info.status ?? ""
                }
                InfoRow {
                    label: "org"
                    value: root._info.registrantOrg ?? ""
                }
                InfoRow {
                    label: "abuse email"
                    value: root._info.abuseEmail ?? ""
                }
                InfoRow {
                    label: "whois srv"
                    value: root._info.port43 ?? ""
                }
            }
        }

        Item {
            visible: !root._loading && !root._error && (root._info.type ?? "") === "asn"
            Layout.fillWidth: true
            implicitHeight: asnRows.implicitHeight

            ColumnLayout {
                id: asnRows
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
                    label: "asn"
                    value: root._info.asn ?? ""
                }
                InfoRow {
                    label: "name"
                    value: root._info.name ?? ""
                }
                InfoRow {
                    label: "country"
                    value: root._info.country ?? ""
                }
                InfoRow {
                    label: "handle"
                    value: root._info.handle ?? ""
                }
            }
        }

        Text {
            visible: !root._loading && !root._error && Object.keys(root._info).length === 0 && root._raw !== "" && root._errorMsg === ""
            Layout.fillWidth: true
            text: "No data parsed from RDAP response"
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
            font.family: Config.fontFamily
            font.italic: true
            opacity: 0.5
            wrapMode: Text.Wrap
        }

        Flow {
            visible: !root._loading && !root._error
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy " + (root._isIp ? "ip" : root._isAsn ? "asn" : "domain")
                primary: true
                onTapped: {
                    copyProc.command = ["wl-copy", root.subject.trim()];
                    copyProc.running = true;
                }
            }
            PillBtn {
                label: "󰖟  open in browser"
                showBtn: !root._isIp && !root._isAsn
                onTapped: {
                    browserProc.command = ["xdg-open", "https://" + root.subject.trim()];
                    browserProc.running = true;
                }
            }
            PillBtn {
                label: "󰆏  copy rdap output"
                showBtn: root._raw !== ""
                onTapped: {
                    copyProc.command = ["wl-copy", root._raw];
                    copyProc.running = true;
                }
            }
            PillBtn {
                label: "󰆏  copy abuse email"
                showBtn: (root._info.abuseEmail ?? "") !== ""
                onTapped: {
                    copyProc.command = ["wl-copy", root._info.abuseEmail];
                    copyProc.running = true;
                }
            }
        }
    }
}
