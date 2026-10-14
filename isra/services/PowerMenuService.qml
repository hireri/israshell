pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.services

Singleton {
    id: root

    readonly property string reservedKeys: "LESHPR"

    readonly property var catalogIds: ["firmware", "hybrid", "exit"]
    readonly property var catalog: ({
            firmware: { labelKey: "logout.firmware", busyKey: "logout.busy_reboot", icon: "memory", command: "loginctl reboot --firmware-setup", key: "F" },
            hybrid: { labelKey: "logout.hybrid_sleep", busyKey: "logout.busy_hybrid_sleep", icon: "ac-unit", command: "loginctl hybrid-sleep", key: "Y" },
            exit: { labelKey: "logout.exit_compositor", busyKey: "logout.busy_exit_compositor", icon: "logout", command: "hyprctl dispatch exit", key: "X" }
        })

    function reconcile(cfg) {
        const raw = Array.isArray(cfg?.entries) ? cfg.entries : [];
        const seen = new Set();
        const out = [];
        for (const e of raw) {
            if (!e || typeof e.id !== "string" || e.id === "" || seen.has(e.id))
                continue;
            const key = typeof e.key === "string" ? e.key.trim().toUpperCase().charAt(0) : "";
            if (root.catalogIds.includes(e.id)) {
                out.push(key ? { id: e.id, key: key } : { id: e.id });
            } else if (typeof e.command === "string" && e.command.trim() !== "") {
                out.push({
                    id: e.id,
                    label: typeof e.label === "string" ? e.label : "",
                    icon: typeof e.icon === "string" && e.icon !== "" ? e.icon : "scripts",
                    command: e.command,
                    key: key,
                    hold: e.hold === true
                });
            } else {
                continue;
            }
            seen.add(e.id);
        }
        return { entries: out };
    }

    function _pickKey(pref, text, used) {
        const own = (pref.toUpperCase().charAt(0) + text.toUpperCase()).replace(/[^A-Z]/g, "");
        for (const c of own) {
            if (!used.has(c)) {
                used.add(c);
                return c;
            }
        }
        for (let i = 0; i < 26; i++) {
            const c = String.fromCharCode(65 + i);
            if (!used.has(c)) {
                used.add(c);
                return c;
            }
        }
        return "";
    }

    function _resolve(list) {
        const used = new Set(root.reservedKeys.split(""));
        return list.map(e => {
            const b = root.catalogIds.includes(e.id) ? root.catalog[e.id] : null;
            const text = b ? Localization.t(b.labelKey) : (e.label || e.id);
            const command = b ? b.command : e.command;
            const key = root._pickKey(e.key || b?.key || "", text, used);
            return {
                id: e.id,
                builtin: b !== null,
                text: text,
                icon: b ? b.icon : e.icon,
                command: command,
                key: key,
                keybind: key === "" ? 0 : key.charCodeAt(0),
                needsAuth: /\bpkexec\b/.test(command),
                hold: b ? true : e.hold === true,
                busyText: b ? Localization.t(b.busyKey) : Localization.t("logout.busy_custom")
            };
        });
    }

    readonly property var entries: root._resolve(Config.powerMenu?.entries ?? [])

    property var running: null
    property var screen: null
    property bool authDone: false
    property string error: ""
    property string _lastErr: ""
    property bool _cancelled: false

    readonly property string phase: {
        if (root.running === null)
            return "idle";
        if (root.running.needsAuth && PolkitService.active)
            return "auth";
        if (root.running.needsAuth && !root.authDone)
            return "waiting";
        return "working";
    }

    readonly property bool promptInline: root.running !== null && root.running.needsAuth && PowerMenuState.visible && PolkitService.idNames.length <= 1

    signal finished(var entry, bool ok)

    function run(entry, screen) {
        if (root.running !== null)
            return;
        root.error = "";
        if (!entry.needsAuth && !entry.hold) {
            Quickshell.execDetached(["sh", "-c", entry.command]);
            root.finished(entry, true);
            return;
        }
        root._lastErr = "";
        root._cancelled = false;
        root.authDone = false;
        root.screen = screen;
        root.running = entry;
        proc.command = ["sh", "-c", entry.command];
        proc.running = true;
    }

    function cancel() {
        if (root.running === null)
            return;
        root._cancelled = true;
        if (root.phase === "auth")
            PolkitService.cancel();
        else if (root.phase === "waiting") {
            Quickshell.execDetached(["pkill", "-TERM", "-P", String(proc.processId)]);
            proc.signal(15);
        }
    }

    Connections {
        target: PolkitService
        function onActiveChanged() {
            if (!PolkitService.active && root.running !== null)
                root.authDone = true;
        }
    }

    Timer {
        interval: 1200
        running: root.phase === "waiting"
        onTriggered: root.authDone = true
    }

    Connections {
        target: PowerMenuState
        function onVisibleChanged() {
            if (PowerMenuState.visible && root.running === null)
                root.error = "";
        }
    }

    Process {
        id: proc

        stderr: SplitParser {
            onRead: data => {
                if (data.trim() !== "")
                    root._lastErr = data.trim();
            }
        }

        onExited: (code, status) => {
            const entry = root.running;
            root.running = null;
            root.screen = null;
            const ok = code === 0;
            if (!ok && !root._cancelled && code !== 126)
                root.error = root._lastErr !== "" ? root._lastErr : Localization.t("logout.failed").arg(code);
            root.finished(entry, ok);
        }
    }
}
