pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0

    property bool ethConnected: false

    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") {
                    netStateProc.running = true;
                }
            }
        }
    }

    Process {
        id: netStateProc
        running: true

        command: ["sh", "-c", "nmcli -t radio wifi; nmcli -t -f TYPE,STATE,CONNECTION dev"]

        stdout: StdioCollector {
            id: netStateOutput
            onStreamFinished: {
                const lines = netStateOutput.text.trim().split('\n');
                if (lines.length === 0)
                    return;

                root.wifiEnabled = (lines[0] === "enabled");

                let isEth = false;
                let isWifi = false;
                let ssid = "";

                for (let i = 1; i < lines.length; i++) {
                    const parts = lines[i].split(':');

                    if (parts[0] === "ethernet" && parts[1] === "connected") {
                        isEth = true;
                    }
                    if (parts[0] === "wifi" && parts[1] === "connected") {
                        isWifi = true;
                        ssid = parts.slice(2).join(':');
                    }
                }

                root.ethConnected = isEth;
                root.wifiConnected = isWifi;
                root.wifiSsid = ssid;

                if (isWifi)
                    signalProc.running = true;
                else
                    root.wifiSignal = 0;
            }
        }
    }

    Timer {
        interval: 10000
        running: root.wifiConnected
        repeat: true
        onTriggered: signalProc.running = true
    }

    Process {
        id: signalProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '*' | cut -d: -f2"]
        stdout: StdioCollector {
            id: signalOutput
            onStreamFinished: {
                const sig = parseInt(signalOutput.text.trim(), 10);
                if (!isNaN(sig)) {
                    root.wifiSignal = sig;
                }
            }
        }
    }

    Process {
        id: enableProc
        command: ["nmcli", "radio", "wifi", "on"]
    }

    Process {
        id: disableProc
        command: ["nmcli", "radio", "wifi", "off"]
    }

    function toggle() {
        if (root.wifiEnabled) {
            root.wifiEnabled = false;
            disableProc.running = true;
        } else {
            root.wifiEnabled = true;
            enableProc.running = true;
        }
    }
}
