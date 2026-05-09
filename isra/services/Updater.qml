pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.style

Singleton {
    id: root

    readonly property string currentVersion: _currentVersion
    readonly property string latestVersion: _latestVersion
    readonly property bool updateAvailable: _updateAvailable
    readonly property bool checking: _checkProc.running || _depProc.running
    readonly property bool applying: _applyInProgress

    property string _currentVersion: ""
    property string _latestVersion: ""
    property bool _updateAvailable: false
    property bool _applyInProgress: false

    readonly property string _scriptsDir: Qt.resolvedUrl("../scripts").toString().replace("file://", "")
    readonly property string _repoRoot: _scriptsDir.replace(/\/isra\/scripts\/?$/, "")

    Process {
        id: _versionProc
        command: ["git", "-C", root._repoRoot, "describe", "--tags", "--abbrev=0"]

        property string _stdout: ""

        stdout: SplitParser {
            onRead: data => _versionProc._stdout += data
        }

        onExited: (code, _status) => {
            const tag = _versionProc._stdout.trim();
            _versionProc._stdout = "";
            if (code === 0 && tag.length > 0) {
                root._currentVersion = tag;
                console.log("[Updater] initial version:", tag);
            } else {
                console.warn("[Updater] could not read git tag for initial version");
            }
        }
    }

    Process {
        id: _depProc
        command: ["bash", root._scriptsDir + "/check-deps.sh"]

        property string _stdout: ""

        stdout: SplitParser {
            onRead: data => _depProc._stdout += data + "\n"
        }

        onExited: (code, _status) => {
            console.log("[Updater] check-deps.sh exited with code", code);
            _depProc._stdout = "";
            if (code === 0) {
                console.log("[Updater] all dependencies satisfied");
            } else if (code === 1) {
                const missing = _depProc._stdout.trim().split("\n").filter(s => s.length > 0);
                console.warn("[Updater] missing dependencies:", missing.join(", "));
                if (missing.length > 0)
                    _notify("Missing dependencies", "These packages are required:\n" + missing.join(", "), "dialog-warning", "critical", 0);
            } else if (code === 2) {
                console.warn("[Updater] check-deps.sh error — deps file missing?");
            }
        }
    }

    Process {
        id: _checkProc
        command: ["bash", root._scriptsDir + "/check-update.sh"]

        environment: ({
                "GITHUB_REPO": Config.githubRepo,
                "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            })

        property string _stdout: ""

        stdout: SplitParser {
            onRead: data => _checkProc._stdout += data + "\n"
        }

        onExited: (code, _status) => {
            console.log("[Updater] check-update.sh exited with code", code);
            const lines = _checkProc._stdout.trim().split("\n").filter(s => s.length > 0);
            _checkProc._stdout = "";

            if (lines.length >= 2) {
                root._currentVersion = lines[0].trim();
                root._latestVersion = lines[1].trim();
                console.log("[Updater] current:", root._currentVersion, "/ latest:", root._latestVersion);
            } else {
                console.warn("[Updater] unexpected output from check-update.sh:", lines.join("|"));
            }

            if (code === 1) {
                console.log("[Updater] update available, prompting user");
                root._updateAvailable = true;
                _promptUpdate();
            } else if (code === 2) {
                console.warn("[Updater] check-update.sh returned error");
                _notify("Update check failed", "Could not reach GitHub.", "network-error", "normal", 8000);
            } else {
                console.log("[Updater] already up to date");
                root._updateAvailable = false;
            }
        }
    }

    Process {
        id: _updatePromptProc

        property string _stdout: ""

        stdout: SplitParser {
            onRead: data => _updatePromptProc._stdout += data
        }

        onExited: (code, _status) => {
            const action = _updatePromptProc._stdout.trim();
            _updatePromptProc._stdout = "";

            if (action === "update") {
                console.log("[Updater] user accepted update");
                _applyUpdate();
            } else {
                console.log("[Updater] user deferred update (action: '" + action + "')");
            }
        }
    }

    Process {
        id: _applyProc
        command: ["bash", root._scriptsDir + "/do-update.sh"]

        property string _stdout: ""

        stdout: SplitParser {
            onRead: data => _applyProc._stdout += data + "\n"
        }

        onExited: (code, _status) => {
            const out = _applyProc._stdout.trim();
            _applyProc._stdout = "";
            root._applyInProgress = false;

            console.log("[Updater] do-update.sh exited with code", code);
            if (out.length > 0)
                console.log("[Updater] do-update.sh output:\n" + out);

            if (code === 0) {
                const doneLine = out.split("\n").find(l => l.startsWith("done:")) ?? "";
                const newVer = doneLine.replace("done:", "").trim() || root._latestVersion;
                console.log("[Updater] update applied, now on", newVer);
                root._currentVersion = newVer;
                root._updateAvailable = false;

                _notify("Shell updated", "Now running " + newVer + "\nRestarting QuickShell...", "software-update-available", "low", 4000);

                _restartProc.running = true;
            } else {
                console.warn("[Updater] do-update.sh failed:\n" + out);
                _notify("Update failed", "Something went wrong, check journalctl for details.", "dialog-error", "critical", 0);
            }
        }
    }

    Process {
        id: _restartProc
        command: ["bash", "-c", "sleep 0.4; setsid bash -c 'sleep 0.4; kill $(pidof quickshell); sleep 0.1; qs -c isra' &"]

        onExited: (code, _status) => {
            console.log("[Updater] restart dispatched (code " + code + ")");
        }
    }

    Timer {
        id: _pollTimer
        interval: 60 * 60 * 1000
        repeat: true
        running: Config.checkUpdates
        onTriggered: {
            console.log("[Updater] poll timer triggered");
            root.checkNow();
        }
    }

    Component.onCompleted: {
        console.log("[Updater] initialized — scriptsDir:", root._scriptsDir);
        console.log("[Updater] repoRoot:", root._repoRoot);
        console.log("[Updater] githubRepo:", Config.githubRepo);
        console.log("[Updater] checkDeps:", Config.checkDeps, "/ checkUpdates:", Config.checkUpdates);
        _versionProc.running = true;
        if (Config.checkDeps) {
            console.log("[Updater] starting dependency check");
            _depProc.running = true;
        }
        if (Config.checkUpdates) {
            console.log("[Updater] starting update check");
            root.checkNow();
        }
    }

    function checkNow() {
        if (_checkProc.running || _applyInProgress) {
            console.log("[Updater] checkNow skipped — already running");
            return;
        }
        _checkProc.running = true;
    }

    function _promptUpdate() {
        if (_updatePromptProc.running) {
            console.log("[Updater] prompt already visible, skipping");
            return;
        }
        _updatePromptProc.command = ["notify-send", "--action=update=  Update Now", "--action=later=  Later", "-u", "normal", "-i", "software-update-available", "-a", "QuickShell", "-t", "0", "Update available  " + root._latestVersion, "Currently on " + root._currentVersion + "\nUpdate will restart the shell when done."];
        _updatePromptProc.running = true;
    }

    function _applyUpdate() {
        if (_applyProc.running) {
            console.warn("[Updater] _applyUpdate skipped — already running");
            return;
        }
        console.log("[Updater] starting apply");
        root._applyInProgress = true;
        _notify("Updating QuickShell...", root._currentVersion + " → " + root._latestVersion + "\nThis will only take a moment.", "software-update-available", "low", 6000);
        _applyProc.running = true;
    }

    function _notify(summary, body, icon, urgency, timeout) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = ["notify-send", "-u", urgency, "-i", icon, "-a", "QuickShell", "-t", String(timeout ?? 5000), summary, body];
        proc.onExited.connect(() => proc.destroy());
        proc.running = true;
    }
}
