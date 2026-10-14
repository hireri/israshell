pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import "ShellQuote.js" as ShellQuote
import "vpnInfo.js" as VpnInfo

Singleton {
    id: root

    readonly property bool isOnline: wifiConnected || ethConnected

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property bool ethConnected: false
    property bool vpnConnected: false
    property string vpnName: ""
    property var vpnProfiles: []
    property var vpnActive: []
    property var vpnEndpoints: ({})
    property string _vpnUuidKey: ""
    property var vpnStats: ({})
    property bool vpnStatsWanted: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool scanning: false
    property bool wifiConnecting: false
    property bool ethAvailable: false

    property string pendingPasswordSsid: ""
    property bool awaitingPassword: false
    property bool passwordFailed: false
    property var _knownSsids: new Set()

    property bool _netReady: false
    onWifiConnectedChanged: {
        if (!root._netReady)
            return;
        if (root.wifiConnected) {
            wifiNotifyInfoProc.running = false;
            wifiNotifyInfoProc.running = true;
        } else {
            root._notifyNet(Localization.t("sysNotify.wifi"), false, "wifi-off");
        }
    }
    onEthConnectedChanged: if (root._netReady) root._notifyNet(Localization.t("networkPage.ethernet"), root.ethConnected, "ethernet")

    function _wifiIconFor(strength, secured) {
        const tier = strength >= 80 ? 80 : strength >= 75 ? 75 : strength >= 50 ? 50 : strength >= 25 ? 25 : 0;
        return secured ? "wifi-locked-" + tier : (tier === 80 ? "wifi" : "wifi-" + tier);
    }

    Process {
        id: wifiNotifyInfoProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SECURITY d wifi | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":");
                const strength = parseInt(parts[1]) || 0;
                const secured = (parts[2] || "").length > 0;
                root._notifyNet(Localization.t("sysNotify.wifi"), true, root._wifiIconFor(strength, secured));
            }
        }
    }

    function _notifyNet(label, connected, icon) {
        if (!Config.notifications.network)
            return;
        const text = Localization.t(connected ? "sysNotify.connected" : "sysNotify.disconnected").arg(label);
        netNotifyProc.command = ["notify-send", "-u", "low", "-a", "Network", "-t", "4000", "-h", "string:x-material-icon:" + icon, Localization.t("sysNotify.connectivity"), text];
        netNotifyProc.running = false;
        netNotifyProc.running = true;
    }

    readonly property var networks: []
    readonly property var activeNetwork: networks.find(n => n.active) ?? null

    readonly property var sortedNetworks: [...networks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })

    function toggle() {
        enableWifiProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        enableWifiProc.running = false;
        enableWifiProc.running = true;
    }

    function setScanning(enabled) {
        if (enabled) {
            scanning = true;
            rescanProc.running = false;
            rescanProc.running = true;
        }
    }

    function connectNetwork(ssid) {
        wifiConnecting = true;
        connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connectProc.running = false;
        connectProc.running = true;
    }

    function requestPassword(ssid) {
        passwordFailed = false;
        pendingPasswordSsid = ssid;
        awaitingPassword = true;
    }

    function cancelPassword() {
        awaitingPassword = false;
        passwordFailed = false;
        pendingPasswordSsid = "";
    }

    function connectWithPassword(ssid, password) {
        wifiConnecting = true;
        passwordFailed = false;
        connectPasswordProc.ssid = ssid;
        connectPasswordProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        connectPasswordProc.running = false;
        connectPasswordProc.running = true;
    }

    function changePassword(ssid, password) {
        wifiConnecting = true;
        passwordFailed = false;
        changePasswordProc.command = ["bash", "-c", `nmcli connection modify ${ShellQuote.shQuote(ssid)} wifi-sec.psk ${ShellQuote.shQuote(password)} && nmcli dev wifi connect ${ShellQuote.shQuote(ssid)}`];
        changePasswordProc.running = false;
        changePasswordProc.running = true;
    }

    function _passwordAttemptDone(code) {
        wifiConnecting = false;
        if (code === 0)
            cancelPassword();
        else
            passwordFailed = true;
        _updateAll();
    }

    function disconnectNetwork(ssid) {
        disconnectProc.command = ["nmcli", "connection", "down", ssid];
        disconnectProc.running = false;
        disconnectProc.running = true;
    }

    function forgetNetwork(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", ssid];
        forgetProc.running = false;
        forgetProc.running = true;
    }

    function toggleEthernet() {
        ethFindProc.wantDisconnect = root.ethConnected;
        ethFindProc.running = false;
        ethFindProc.running = true;
    }

    function _updateAll() {
        updateDebounce.restart();
    }

    function refresh() {
        _updateAll();
        signalTimer.restart();
    }

    Timer {
        id: updateDebounce
        interval: 300
        repeat: false
        onTriggered: {
            wifiRadioProc.running = false;
            wifiRadioProc.running = true;
            stateProc.running = false;
            stateProc.running = true;
            networksProc.running = false;
            networksProc.running = true;
            signalProc.running = false;
            signalProc.running = true;
            vpnProc.running = false;
            vpnProc.running = true;
            knownProc.running = false;
            knownProc.running = true;
        }
    }

    Process {
        id: vpnProc
        running: true
        command: ["nmcli", "-t", "-f", "TYPE,NAME,UUID,ACTIVE,TIMESTAMP,DEVICE,AUTOCONNECT", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const profiles = [];
                for (const line of text.trim().split("\n")) {
                    const parts = line.replace(/\\:/g, "\u0000").split(":").map(x => x.replace(/\u0000/g, ":"));
                    if (parts.length < 5 || (parts[0] !== "vpn" && parts[0] !== "wireguard"))
                        continue;
                    profiles.push({ name: parts[1], uuid: parts[2], active: parts[3] === "yes", last: Number(parts[4]) || 0, device: parts[5] ?? "", boot: parts[6] === "yes" });
                }
                profiles.sort((a, b) => b.last - a.last);
                root.vpnProfiles = profiles;
                root.vpnActive = profiles.filter(p => p.active);
                root.vpnName = root.vpnActive[0]?.name ?? "";
                root.vpnConnected = root.vpnActive.length > 0;
                const key = profiles.map(p => p.uuid).sort().join(",");
                if (key !== root._vpnUuidKey) {
                    root._vpnUuidKey = key;
                    vpnEndpointProc.command = ["sh", "-c", 'for u; do echo "$u $(nmcli -t -g wireguard.peers connection show uuid "$u" 2>/dev/null)"; done', "_", ...profiles.map(p => p.uuid)];
                    vpnEndpointProc.running = false;
                    vpnEndpointProc.running = true;
                }
            }
        }
    }

    Process {
        id: vpnEndpointProc
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const m = line.match(/^(\S+) .*endpoint=(\S+)/);
                    if (m)
                        map[m[1]] = m[2].replace(/\\?:\d+$/, "");
                }
                root.vpnEndpoints = map;
            }
        }
    }

    Process {
        id: vpnToggleProc
        onExited: {
            vpnProc.running = false;
            vpnProc.running = true;
        }
    }

    function _vpnRun(args) {
        vpnToggleProc.command = ["nmcli", ...args];
        vpnToggleProc.running = false;
        vpnToggleProc.running = true;
    }
    function vpnConnect(uuid) {
        vpnToggleProc.command = ["sh", "-c", 'target=$1; shift; for u; do nmcli connection down uuid "$u"; done; nmcli connection up uuid "$target"', "_", uuid, ...vpnActive.map(p => p.uuid).filter(u => u !== uuid)];
        vpnToggleProc.running = false;
        vpnToggleProc.running = true;
    }
    function vpnDisconnect(uuid) { _vpnRun(["connection", "down", "uuid", uuid]); }
    function vpnRename(uuid, name) { if (name.trim() !== "") _vpnRun(["connection", "modify", "uuid", uuid, "connection.id", name.trim()]); }
    function vpnSetBoot(uuid) {
        const on = vpnProfiles.find(p => p.uuid === uuid)?.boot ? "no" : "yes";
        vpnToggleProc.command = ["sh", "-c", 'target=$1; val=$2; shift 2; for u; do nmcli connection modify uuid "$u" connection.autoconnect no; done; nmcli connection modify uuid "$target" connection.autoconnect "$val"', "_", uuid, on, ...vpnProfiles.map(p => p.uuid)];
        vpnToggleProc.running = false;
        vpnToggleProc.running = true;
    }
    function vpnDelete(uuid) { _vpnRun(["connection", "delete", "uuid", uuid]); }
    function vpnImport(urls) {
        const files = urls.map(u => String(u).replace(/^file:\/\//, "")).filter(f => f.endsWith(".conf"));
        if (files.length === 0)
            return;
        vpnToggleProc.command = ["sh", "-c", 'for f; do nmcli connection import type wireguard file "$f" && nmcli connection modify "$(basename "${f%.conf}")" connection.autoconnect no; done', "_", ...files];
        vpnToggleProc.running = false;
        vpnToggleProc.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.vpnStatsWanted && root.vpnConnected
        triggeredOnStart: true
        onTriggered: {
            vpnStatsProc.command = ["sh", "-c", 'for d; do [ -r /sys/class/net/$d/statistics/rx_bytes ] && echo "$d $(cat /sys/class/net/$d/statistics/rx_bytes) $(cat /sys/class/net/$d/statistics/tx_bytes)"; done', "_", ...root.vpnActive.map(p => p.device).filter(d => d !== "")];
            vpnStatsProc.running = false;
            vpnStatsProc.running = true;
        }
    }

    Process {
        id: vpnStatsProc
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.trim().split("\n")) {
                    const [dev, rx, tx] = line.split(" ");
                    if (dev && tx !== undefined)
                        map[dev] = { rx: Number(rx), tx: Number(tx) };
                }
                root.vpnStats = map;
            }
        }
    }

    function vpnSubtitle(p) {
        if (!p)
            return "";
        const parts = [];
        const loc = VpnInfo.location(vpnEndpoints[p.uuid]);
        if (loc)
            parts.push(loc);
        const st = p.active ? vpnStats[p.device] : null;
        if (st)
            parts.push("↓ " + VpnInfo.formatBytes(st.rx) + "  ↑ " + VpnInfo.formatBytes(st.tx));
        return parts.join("  ·  ");
    }

    function vpnDisconnectAll() {
        vpnToggleProc.command = ["sh", "-c", 'for u; do nmcli connection down uuid "$u"; done', "_", ...vpnActive.map(p => p.uuid)];
        vpnToggleProc.running = false;
        vpnToggleProc.running = true;
    }

    function toggleVpn() {
        if (vpnConnected)
            vpnDisconnectAll();
        else if (vpnProfiles.length > 0)
            vpnConnect(vpnProfiles[0].uuid);
    }

    Process {
        id: ethFindProc
        property bool wantDisconnect: false
        command: ["sh", "-c", "nmcli -t -f TYPE,DEVICE d status | awk -F: '/^ethernet/{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim();
                if (!dev)
                    return;
                ethToggleProc.command = ethFindProc.wantDisconnect ? ["nmcli", "device", "disconnect", dev] : ["nmcli", "device", "connect", dev];
                ethToggleProc.running = false;
                ethToggleProc.running = true;
            }
        }
    }

    Process {
        id: monitorProc
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "")
                    root._updateAll();
            }
        }
    }

    Process {
        id: wifiRadioProc
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: stateProc
        running: true
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status; nmcli -t -f ACTIVE-CONNECTION,SIGNAL,SSID d wifi 2>/dev/null | grep '^[^:]*:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.trim());
                let eth = false, wifi = false;

                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts[0] === "ethernet" && parts[1] === "connected")
                        eth = true;
                    if (parts[0] === "wifi" && parts[1] === "connected")
                        wifi = true;
                }

                root.ethConnected = eth;
                root.ethAvailable = lines.some(l => l.split(":")[0] === "ethernet");
                root.wifiConnected = wifi;
                root._netReady = true;
            }
        }
    }

    Process {
        id: netNotifyProc
    }

    Process {
        id: signalProc
        running: true
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SSID d wifi | grep '^\\*'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (!line) {
                    if (!root.wifiConnecting) {
                        root.wifiSsid = "";
                        root.wifiSignal = 0;
                    }
                    return;
                }
                const parts = line.split(":");
                root.wifiSignal = parseInt(parts[1]) || 0;
                root.wifiSsid = parts.slice(2).join(":").trim();
            }
        }
    }

    Timer {
        id: signalTimer
        interval: 10000
        running: root.wifiConnected
        repeat: true
        onTriggered: {
            signalProc.running = false;
            signalProc.running = true;
        }
    }

    Process {
        id: networksProc
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "__COLON__";
                const allNets = text.trim().split("\n").map(line => {
                    const parts = line.replace(/\\:/g, PLACEHOLDER).split(":");
                    return {
                        active: parts[0] === "yes",
                        strength: parseInt(parts[1]) || 0,
                        frequency: parseInt(parts[2]) || 0,
                        ssid: parts[3]?.replace(/__COLON__/g, ":") ?? "",
                        bssid: parts[4]?.replace(/__COLON__/g, ":") ?? "",
                        security: parts[5] || "",
                        known: root._knownSsids.has(parts[3]?.replace(/__COLON__/g, ":") ?? "")
                    };
                }).filter(n => n.ssid.length > 0);

                const map = new Map();
                for (const n of allNets) {
                    const ex = map.get(n.ssid);
                    if (!ex || (n.active && !ex.active) || (!n.active && !ex.active && n.strength > ex.strength))
                        map.set(n.ssid, n);
                }

                const newNets = Array.from(map.values());

                for (const n of newNets) {
                    const existing = root.networks.find(e => e.ssid === n.ssid);
                    if (existing) {
                        Object.assign(existing, n);
                    } else {
                        root.networks.push(n);
                    }
                }
                for (let i = root.networks.length - 1; i >= 0; i--) {
                    if (!newNets.find(n => n.ssid === root.networks[i].ssid))
                        root.networks.splice(i, 1);
                }

                root.networksChanged();
            }
        }
    }

    Process {
        id: knownProc
        running: true
        command: ["nmcli", "-g", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const known = new Set(text.trim().split("\n").map(l => l.trim()));
                root._knownSsids = known;
                for (const n of root.networks)
                    n.known = known.has(n.ssid);
                root.networksChanged();
            }
        }
    }

    Process {
        id: enableWifiProc
        onExited: root._updateAll()
    }

    Process {
        id: ethToggleProc
        onExited: root._updateAll()
    }

    Process {
        id: connectProc
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required") || line.includes("password"))
                    root.requestPassword(connectProc.command[connectProc.command.length - 1]);
            }
        }
        onExited: (code, status) => {
            root.wifiConnecting = false;
            root._updateAll();
        }
    }

    Process {
        id: connectPasswordProc
        property string ssid: ""
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        onExited: (code, status) => {
            if (code !== 0) {
                dropFailedProc.command = ["nmcli", "connection", "delete", "id", ssid];
                dropFailedProc.running = false;
                dropFailedProc.running = true;
            }
            root._passwordAttemptDone(code);
        }
    }

    Process {
        id: dropFailedProc
    }

    Process {
        id: changePasswordProc
        onExited: (code, status) => root._passwordAttemptDone(code)
    }

    Process {
        id: disconnectProc
        onExited: root._updateAll()
    }

    Process {
        id: forgetProc
        onExited: root._updateAll()
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: (code, status) => {
            root.scanning = false;
            if (code === 0) {
                networksProc.running = false;
                networksProc.running = true;
            }
        }
    }

    Component.onCompleted: _updateAll()
}
