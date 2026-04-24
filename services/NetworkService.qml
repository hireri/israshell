pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property bool ethConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool scanning: false
    property bool wifiConnecting: false
    property bool wifiAvailable: true
    property bool ethAvailable: false

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
        wifiRadioProc.running = false;
        wifiRadioProc.running = true;
        stateProc.running = false;
        stateProc.running = true;
        networksProc.running = false;
        networksProc.running = true;
        signalProc.running = false;
        signalProc.running = true;
    }

    function refresh() {
        _updateAll();
        signalTimer.restart();
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
                    _updateAll();
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
            }
        }
    }

    Process {
        id: signalProc
        running: true
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SSID d wifi | grep '^\\*'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (!line) {
                    root.wifiSsid = "";
                    root.wifiSignal = 0;
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
                        known: false
                    };
                }).filter(n => n.ssid.length > 0);

                const map = new Map();
                for (const n of allNets) {
                    const ex = map.get(n.ssid);
                    if (!ex || (n.active && !ex.active) || (!n.active && !ex.active && n.strength > ex.strength))
                        map.set(n.ssid, n);
                }

                root.networks.length = 0;
                for (const n of map.values())
                    root.networks.push(n);
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
        onExited: {
            root.wifiConnecting = false;
            root._updateAll();
        }
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
        onExited: {
            root.scanning = false;
            networksProc.running = false;
            networksProc.running = true;
        }
    }

    Component.onCompleted: _updateAll()
}
