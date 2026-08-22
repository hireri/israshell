pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.style

Singleton {
    id: root

    property string presetsDir: Config.configDir + "/presets"
    property var entries: []      // [{ name, mtime, path }]
    property bool busy: false
    property string statusMessage: ""
    property bool statusIsError: false

    property int nowTick: 0
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.nowTick++
    }

    function relativeTime(epochSeconds) {
        const diff = Math.max(0, Date.now() / 1000 - epochSeconds);
        if (diff < 60)
            return Localization.t("configPresetService.just_now");
        if (diff < 3600)
            return Localization.t("configPresetService.minutes_ago").arg(Math.floor(diff / 60));
        if (diff < 86400)
            return Localization.t("configPresetService.hours_ago").arg(Math.floor(diff / 3600));
        if (diff < 2592000)
            return Localization.t("configPresetService.days_ago").arg(Math.floor(diff / 86400));
        return Localization.t("configPresetService.months_ago").arg(Math.floor(diff / 2592000));
    }

    function refresh() {
        listProc.running = false;
        listProc.running = true;
    }

    function savePreset() {
        root.busy = true;
        root.statusMessage = "";
        const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        const configPath = Config.configPath;
        const destPath = root.presetsDir + "/preset-" + ts + ".json";
        saveProc.command = ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.presetsDir) +
            " && cp " + JSON.stringify(configPath) + " " + JSON.stringify(destPath)];
        saveProc.running = false;
        saveProc.running = true;
    }

    function deletePreset(path) {
        deleteProc.command = ["rm", "-f", path];
        deleteProc.running = false;
        deleteProc.running = true;
    }

    function applyPreset(path) {
        root.statusMessage = "";
        readFileView.path = path;
    }

    Process {
        id: saveProc
        running: false
        onExited: (code, _) => {
            root.busy = false;
            if (code === 0) {
                root.refresh();
            } else {
                root.statusMessage = Localization.t("configPresetService.save_failed_exit").arg(code);
                root.statusIsError = true;
            }
        }
    }

    Process {
        id: deleteProc
        running: false
        onExited: (code, _) => {
            if (code === 0)
                root.refresh();
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.presetsDir) +
            " && find " + JSON.stringify(root.presetsDir) +
            " -maxdepth 1 -type f -name '*.json' -printf '%T@\\t%f\\t%p\\n'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.trim().length > 0);
                const list = lines.map(l => {
                    const p = l.split("\t");
                    return {
                        mtime: parseFloat(p[0]) || 0,
                        name: p[1] ?? "",
                        path: p[2] ?? ""
                    };
                }).filter(e => e.name.length > 0);
                list.sort((a, b) => b.mtime - a.mtime);
                root.entries = list;
            }
        }
    }

    FileView {
        id: readFileView
        path: ""
        blockLoading: true
        onLoaded: {
            if (readFileView.path === "")
                return;
            try {
                const parsed = JSON.parse(readFileView.text());
                Config.update(parsed);
            } catch (e) {
                root.statusMessage = Localization.t("configPresetService.apply_failed_could_not_parse");
                root.statusIsError = true;
                console.log("[ConfigPresetService] apply parse error:", e);
            }
        }
        onLoadFailed: error => {
            root.statusMessage = Localization.t("configPresetService.could_not_read_preset_file");
            root.statusIsError = true;
            console.log("[ConfigPresetService] apply load error:", error);
        }
    }

    Component.onCompleted: refresh()
}
