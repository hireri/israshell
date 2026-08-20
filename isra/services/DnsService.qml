pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    readonly property var providers: [
        { id: "cloudflare", label: "Cloudflare", v4: "1.1.1.1,1.0.0.1", v6: "2606:4700:4700::1111,2606:4700:4700::1001" },
        { id: "google", label: "Google", v4: "8.8.8.8,8.8.4.4", v6: "2001:4860:4860::8888,2001:4860:4860::8844" },
        { id: "quad9", label: "Quad9", v4: "9.9.9.9,149.112.112.112", v6: "2620:fe::fe,2620:fe::9" },
        { id: "nextdns", label: "NextDNS", v4: "45.90.28.0,45.90.30.0", v6: "2a07:a8c0::,2a07:a8c1::" }
    ]

    readonly property var _providerMap: {
        const m = {};
        for (const p of providers)
            m[p.id] = p;
        return m;
    }

    readonly property bool enabled: Config.dns.enabled
    readonly property string providerId: Config.dns.provider
    readonly property var currentProvider: root._providerMap[root.providerId] ?? root.providers[0]

    property string _pendingAction: ""
    property string _pendingProviderId: ""

    function apply(id) {
        if (!root._providerMap[id])
            return;
        root._pendingAction = "apply";
        root._pendingProviderId = id;
        activeConnProc.running = false;
        activeConnProc.running = true;
    }

    function disable() {
        root._pendingAction = "disable";
        activeConnProc.running = false;
        activeConnProc.running = true;
    }

    function cycle() {
        const ids = root.providers.map(p => p.id);
        if (!root.enabled) {
            root.apply(ids[0]);
            return;
        }
        const nextIdx = ids.indexOf(root.providerId) + 1;
        if (nextIdx >= ids.length)
            root.disable();
        else
            root.apply(ids[nextIdx]);
    }

    Process {
        id: activeConnProc
        command: ["sh", "-c", "nmcli -t -f UUID,DEVICE,STATE connection show --active | awk -F: '$3==\"activated\" && $2!=\"lo\" {print $1; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const uuid = text.trim();
                if (uuid)
                    root._runFor(uuid);
            }
        }
    }

    function _runFor(connUuid) {
        if (root._pendingAction === "apply") {
            const p = root._providerMap[root._pendingProviderId];
            if (!p)
                return;
            modifyProc.command = ["nmcli", "connection", "modify", connUuid, "ipv4.dns", p.v4, "ipv4.ignore-auto-dns", "yes", "ipv6.dns", p.v6, "ipv6.ignore-auto-dns", "yes"];
            modifyProc.pendingEnabled = true;
            modifyProc.pendingProviderId = p.id;
        } else if (root._pendingAction === "disable") {
            modifyProc.command = ["nmcli", "connection", "modify", connUuid, "ipv4.dns", "", "ipv4.ignore-auto-dns", "no", "ipv6.dns", "", "ipv6.ignore-auto-dns", "no"];
            modifyProc.pendingEnabled = false;
            modifyProc.pendingProviderId = root.providerId;
        } else {
            return;
        }
        modifyProc.pendingConnUuid = connUuid;
        modifyProc.running = false;
        modifyProc.running = true;
    }

    Process {
        id: modifyProc
        property string pendingConnUuid: ""
        property bool pendingEnabled: false
        property string pendingProviderId: ""
        onExited: (code, status) => {
            if (code !== 0)
                return;
            Config.update({
                dns: {
                    enabled: modifyProc.pendingEnabled,
                    provider: modifyProc.pendingProviderId
                }
            });
            reapplyProc.command = ["nmcli", "connection", "up", modifyProc.pendingConnUuid];
            reapplyProc.running = false;
            reapplyProc.running = true;
        }
    }

    Process {
        id: reapplyProc
    }
}
