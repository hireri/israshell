pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _path: Quickshell.env("HOME") + "/.config/quickshell/secrets.enc"
    property var _values: ({})
    property bool ready: false
    property bool _writing: false
    property var _pendingWrite: null

    function get(key: string): string {
        return _values[key] ?? "";
    }

    function set(key: string, value: string): void {
        const updated = Object.assign({}, _values, { [key]: value });
        _values = updated;
        _persist();
    }

    function remove(key: string): void {
        const updated = Object.assign({}, _values);
        delete updated[key];
        _values = updated;
        _persist();
    }

    function _shellQuote(s: string): string {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function _keyDeriveCmd(): string {
        return "MID=$(cat /etc/machine-id 2>/dev/null || cat /var/lib/dbus/machine-id 2>/dev/null || echo nomachineid); " + "printf '%s' \"${MID}:${USER}\" | openssl dgst -sha256 -binary | od -An -tx1 | tr -d ' \\n'";
    }

    Component.onCompleted: _load()

    function _load(): void {
        loadProc.running = false;
        loadProc.command = ["sh", "-c", _keyDeriveCmd() + " > /tmp/.qs-skey-$$ && " + "if [ -f " + _shellQuote(_path) + " ]; then " + "openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass file:/tmp/.qs-skey-$$ -in " + _shellQuote(_path) + " -base64 2>/dev/null; " + "fi; " + "rm -f /tmp/.qs-skey-$$"];
        loadProc.running = true;
    }

    Process {
        id: loadProc
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim();
                if (text !== "") {
                    try {
                        root._values = JSON.parse(text);
                    } catch (e) {
                        console.log("Secrets: decrypt/parse failed, starting empty:", e);
                        root._values = {};
                    }
                } else {
                    root._values = {};
                }
                root.ready = true;
                if (root._pendingWrite !== null)
                    root._doWrite();
            }
        }
    }

    function _persist(): void {
        if (!ready) {
            _pendingWrite = _values;
            return;
        }
        _pendingWrite = _values;
        writeDebouncer.restart();
    }

    Timer {
        id: writeDebouncer
        interval: 300
        onTriggered: root._doWrite()
    }

    function _doWrite(): void {
        if (_writing) {
            return;
        }
        const payload = JSON.stringify(_pendingWrite ?? _values);
        _pendingWrite = null;
        _writing = true;

        const dir = _path.substring(0, _path.lastIndexOf("/"));
        writeProc.command = ["sh", "-c", "mkdir -p " + _shellQuote(dir) + " && " + _keyDeriveCmd() + " > /tmp/.qs-skey-$$ && " + "printf '%s' " + _shellQuote(payload) + " | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass file:/tmp/.qs-skey-$$ -out " + _shellQuote(_path) + " -base64 && " + "chmod 600 " + _shellQuote(_path) + "; " + "rm -f /tmp/.qs-skey-$$"];
        writeProc.running = true;
    }

    Process {
        id: writeProc
        onRunningChanged: {
            if (!running) {
                root._writing = false;
                if (exitCode !== 0)
                    console.log("Secrets: write failed with exit code", exitCode);
                if (root._pendingWrite !== null)
                    root._doWrite();
            }
        }
    }
}
