pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string distroName: "Arch Linux"
    property string distroId: "arch"
    property string logo: "archlinux-logo"
    property string uptime: "unknown"
    property string kernel: "unknown"
    property string session: "unknown"
    property string username: "unknown"
    property string hostname: "unknown"

    property string cpu: "Unknown CPU"
    property string gpu: "Unknown GPU"
    property string memory: "Unknown RAM"
    property string motherboard: "Unknown"
    property string shellName: "Unknown SHELL"
    property string shellVersion: "Unknown SHELLVER"
    property string quickshellVersion: "Unknown"

    readonly property int historyLength: 40
    readonly property int pollInterval: 2000

    signal cycleStarted()

    property real cpuUsage: 0
    property real ramUsage: 0
    property real swapUsage: 0
    property real gpuUsage: -1
    property real cpuTemp: -1
    property real gpuTemp: -1

    property string ramUsedLabel: "—"
    property string ramTotalLabel: "—"
    property string swapUsedLabel: "—"
    property string swapTotalLabel: "—"
    property string gpuVendor: ""

    property string gpuPower: "—"
    property string cpuPower: "—"

    property var cpuHistory: []
    property var ramHistory: []
    property var swapHistory: []
    property var gpuHistory: []
    property var cpuTempHistory: []
    property var gpuTempHistory: []

    property real _stageCpuUsage: 0
    property real _stageRamUsage: 0
    property real _stageSwapUsage: 0
    property real _stageCpuTemp: -1
    property real _stageGpuUsage: -1
    property real _stageGpuTemp: -1
    property string _stageRamUsedLabel: "—"
    property string _stageRamTotalLabel: "—"
    property string _stageSwapUsedLabel: "—"
    property string _stageSwapTotalLabel: "—"

    property string _stageGpuPower: "—"
    property string _stageCpuPower: "—"

    property bool _isFirstRun: true

    function _pushHistory(arrName, value) {
        const arr = root[arrName].slice();
        arr.push(value);
        while (arr.length > root.historyLength)
            arr.shift();
        root[arrName] = arr;
    }

    function _commitMetrics() {
        root.cpuUsage = root._stageCpuUsage;
        root.ramUsage = root._stageRamUsage;
        root.swapUsage = root._stageSwapUsage;
        root.ramUsedLabel = root._stageRamUsedLabel;
        root.ramTotalLabel = root._stageRamTotalLabel;
        root.swapUsedLabel = root._stageSwapUsedLabel;
        root.swapTotalLabel = root._stageSwapTotalLabel;

        root.gpuPower = root._stageGpuPower;
        root.cpuPower = root._stageCpuPower;
        
        if (root._stageCpuTemp !== -1) root.cpuTemp = root._stageCpuTemp;
        if (root._stageGpuUsage !== -1) root.gpuUsage = root._stageGpuUsage;
        if (root._stageGpuTemp !== -1) root.gpuTemp = root._stageGpuTemp;

        root._pushHistory("cpuHistory", root.cpuUsage);
        root._pushHistory("ramHistory", root.ramUsage);
        root._pushHistory("swapHistory", root.swapUsage);
        if (root.cpuTemp >= 0) root._pushHistory("cpuTempHistory", root.cpuTemp);
        if (root.gpuUsage >= 0) root._pushHistory("gpuHistory", root.gpuUsage);
        if (root.gpuTemp >= 0) root._pushHistory("gpuTempHistory", root.gpuTemp);
    }

    property var _prevCpuTotal: 0
    property var _prevCpuIdle: 0

    function _readCpuUsage(statLine) {
        const parts = statLine.trim().split(/\s+/).slice(1).map(Number);
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);

        const prevTotal = root._prevCpuTotal;
        const prevIdle = root._prevCpuIdle;

        const totalDelta = total - prevTotal;
        const idleDelta = idle - prevIdle;

        root._prevCpuTotal = total;
        root._prevCpuIdle = idle;

        if (prevTotal === 0 || totalDelta <= 0)
            return null;

        return Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)));
    }

    function _formatKb(kb) {
        const mb = kb / 1024;
        if (mb < 1024)
            return Math.round(mb) + " MB";
        return (mb / 1024).toFixed(1) + " GB";
    }

    Timer {
        id: usageTimer
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._isFirstRun) {
                root._commitMetrics();
                root.cycleStarted();
            }
            
            fileProcStat.reload();
            fileMemInfo.reload();
            tempProc.running = true;
            gpuProc.running = true;
        }
    }

    FileView {
        id: fileProcStat
        path: "/proc/stat"
        onTextChanged: {
            const text = fileProcStat.text();
            if (!text) return;
            const firstLine = text.split("\n")[0];
            const usage = root._readCpuUsage(firstLine);
            if (usage !== null) {
                root._stageCpuUsage = usage;
            }
        }
    }

    FileView {
        id: fileMemInfo
        path: "/proc/meminfo"
        onTextChanged: {
            const text = fileMemInfo.text();
            if (!text) return;

            const vals = {};
            text.split("\n").forEach(line => {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) vals[m[1]] = parseInt(m[2], 10);
            });

            const memTotal = vals["MemTotal"] || 0;
            const memAvail = vals["MemAvailable"] !== undefined ? vals["MemAvailable"] : vals["MemFree"] || 0;
            const memUsed = Math.max(0, memTotal - memAvail);

            const swapTotal = vals["SwapTotal"] || 0;
            const swapFree = vals["SwapFree"] || 0;
            const swapUsed = Math.max(0, swapTotal - swapFree);

            if (memTotal > 0) {
                root._stageRamUsage = Math.max(0, Math.min(100, 100 * memUsed / memTotal));
                root._stageRamUsedLabel = root._formatKb(memUsed);
                root._stageRamTotalLabel = root._formatKb(memTotal);
            }

            if (swapTotal > 0) {
                root._stageSwapUsage = Math.max(0, Math.min(100, 100 * swapUsed / swapTotal));
                root._stageSwapUsedLabel = root._formatKb(swapUsed);
                root._stageSwapTotalLabel = root._formatKb(swapTotal);
            } else {
                root._stageSwapUsage = 0;
                root._stageSwapUsedLabel = "0 B";
                root._stageSwapTotalLabel = "0 B";
            }
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone*/type 2>/dev/null | paste -sd'|' -; echo '---'; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | paste -sd'|' -"]
        property var _lines: []
        stdout: SplitParser {
            onRead: data => tempProc._lines.push(data)
        }
        onRunningChanged: {
            if (running) {
                tempProc._lines = [];
                return;
            }
            const lines = tempProc._lines;
            const sepIdx = lines.indexOf("---");
            if (sepIdx === -1) return;
            const types = lines.slice(0, sepIdx).join("").split("|").filter(Boolean);
            const temps = lines.slice(sepIdx + 1).join("").split("|").filter(Boolean).map(Number);

            let chosen = -1;
            for (let i = 0; i < types.length; i++) {
                const t = types[i].toLowerCase();
                if (t.includes("x86_pkg_temp") || t.includes("cpu") || t.includes("tctl") || t.includes("tdie")) {
                    chosen = temps[i];
                    break;
                }
            }
            if (chosen === -1 && temps.length > 0) chosen = temps[0];

            if (chosen !== -1 && !isNaN(chosen)) {
                root._stageCpuTemp = chosen > 1000 ? chosen / 1000 : chosen;
            }
        }
    }

    Process {
        id: gpuProc
        command: ["nvtop", "-s"]
        property var _chunks: []
        stdout: SplitParser {
            onRead: data => gpuProc._chunks.push(data)
        }
        onRunningChanged: {
            if (running) {
                gpuProc._chunks = [];
                return;
            }
            try {
                let raw = gpuProc._chunks.join("").trim();
                if (raw && raw !== "") {
                    raw = raw.replace(/"\s+"([^"]+)":/g, '", "$1":');
                    const parsed = JSON.parse(raw);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        let cpuDev = null;
                        let gpuDev = null;

                        for (let i = 0; i < parsed.length; i++) {
                            let dev = parsed[i];
                            let name = dev.device_name || "";
                            let lowName = name.toLowerCase();
                            
                            if (lowName.includes("processor") || lowName.includes("cpu") || lowName.includes("ryzen") || lowName.includes("intel")) {
                                cpuDev = dev;
                            } else {
                                gpuDev = dev;
                            }
                        }

                        if (!gpuDev && parsed.length > 0) {
                            gpuDev = parsed[0];
                        }

                        if (gpuDev) {
                            let usage = parseInt(gpuDev.gpu_util, 10);
                            let temp = parseInt(gpuDev.temp, 10);
                            let name = gpuDev.device_name;

                            if (name) {
                                let lowName = name.toLowerCase();
                                root.gpuVendor = lowName.includes("nvidia") ? "nvidia" : lowName.includes("amd") ? "amd" : "intel";
                                if (root.gpu === "Unknown GPU" || root.gpu === "") root.gpu = name;
                            }

                            if (!isNaN(usage)) root._stageGpuUsage = Math.max(0, Math.min(100, usage));
                            if (!isNaN(temp)) root._stageGpuTemp = temp;
                            root._stageGpuPower = gpuDev.power_draw ? gpuDev.power_draw.trim() : "—";
                        }

                        if (cpuDev) {
                            root._stageCpuPower = cpuDev.power_draw ? cpuDev.power_draw.trim() : "—";
                            let cpuTempFromNvtop = parseInt(cpuDev.temp, 10);
                            if (!isNaN(cpuTempFromNvtop) && root._stageCpuTemp === -1) {
                                root._stageCpuTemp = cpuTempFromNvtop;
                            }
                        }
                    }
                }
            } catch (e) {
                console.warn("nvtop JSON Parsing Exception: ", e);
            }

            if (root._isFirstRun) {
                root._isFirstRun = false;
                root._commitMetrics();
            }
        }
    }

    function formatUptime(seconds) {
        let s = Math.floor(seconds);
        let d = Math.floor(s / 86400);
        s %= 86400;
        let h = Math.floor(s / 3600);
        s %= 3600;
        let m = Math.floor(s / 60);
        let parts = [];
        if (d > 0) parts.push(d + "d");
        if (h > 0) parts.push(h + "h");
        if (m > 0 || parts.length === 0) parts.push(m + "m");
        return parts.join(" ");
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            identityProc.running = true;
            kernelProc.running = true;
            hardwareProc.running = true;
            shellProc.running = true;
            quickshellProc.running = true;
            fileOsRelease.reload();
            fileUptime.reload();
            fileSessionType.reload();
        }
    }

    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: SplitParser {
            onRead: data => root.kernel = data.trim()
        }
    }

    Process {
        id: hardwareProc
        command: ["sh", "-c", "cpu=$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //; s/ Processor//g; s/ CPU//g; s/ @ .*//; s/(R)//g; s/(TM)//g; s/  */ /g; s/^ *//; s/ *$//'); " + "gpu=$(/usr/bin/lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/ \\[[0-9a-f:]\\+\\]//g; s/.*: //' | sed 's/.*\\[\\([^]]*\\)\\].*/\\1/' | grep -iE 'Radeon|GeForce|RTX|GTX|Iris|UHD|Arc|Quadro|Tesla|Mali|Adreno' | sed 's/ \\/ .*//' | head -1); " + "if [ -z \"$gpu\" ]; then " + "  gpu=$(/usr/bin/lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/ \\[[0-9a-f:]\\+\\]//g; s/.*: //; s/.*\\[\\([^]]*\\)\\].*/\\1/; s/ Corporation//g; s/ Inc\\.//g; s/ (rev.*)//g' | head -1); " + "fi; " + "[ -z \"$gpu\" ] && gpu='Unknown GPU'; " + "mem=$(/usr/bin/free -h 2>/dev/null | awk '/^Mem:/ {print $2}'); " + "board='Unknown'; " + "if [ -r /sys/class/dmi/id/board_name ]; then " + "  board=$(cat /sys/class/dmi/id/board_name 2>/dev/null | sed 's/ Corporation//g; s/ Inc\\.//g; s/ Ltd\\.//g; s/ Co\\.//g; s/  */ /g; s/^ *//; s/ *$//'); " + "fi; " + "if [ \"$board\" = 'Unknown' ] || [ -z \"$board\" ]; then " + "  if command -v dmidecode >/dev/null 2>&1 && [ -r /dev/mem ] || [ -r /sys/firmware/dmi/tables/DMI ]; then " + "    board=$(dmidecode -s baseboard-product-name 2>/dev/null | sed 's/ Corporation//g; s/ Inc\\.//g; s/ Ltd\\.//g; s/ Co\\.//g; s/  */ /g; s/^ *//; s/ *$//' | head -1); " + "  fi; " + "fi; " + "[ -z \"$board\" ] && board='Unknown'; " + "echo \"${cpu:-Unknown}|${gpu}|${mem:-Unknown}|${board}\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts[0] && parts[0] !== "Unknown") root.cpu = parts[0];
                if (parts[1] && parts[1] !== "Unknown GPU" && parts[1] !== "" && root.gpu === "Unknown GPU") root.gpu = parts[1];
                if (parts[2] && parts[2] !== "Unknown") {
                    let match = parts[2].match(/^([\d.]+)([A-Za-z]+)$/);
                    if (match) {
                        let value = parseFloat(match[1]);
                        let unit = match[2].toUpperCase();
                        if (unit.startsWith("G")) value = value * 1.073741824;
                        else if (unit.startsWith("M")) value = value * 1.048576;
                        root.memory = Math.round(value) + "GB RAM";
                    } else {
                        root.memory = parts[2].toUpperCase().replace("I", "i") + "B RAM";
                    }
                }
                if (parts[3] && parts[3] !== "Unknown" && parts[3] !== "") root.motherboard = parts[3];
            }
        }
    }

    Process {
        id: shellProc
        command: ["sh", "-c", "echo \"$(basename $SHELL)|$($SHELL --version 2>/dev/null | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -1)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts[0]) {
                    let sName = parts[0];
                    root.shellName = sName.charAt(0).toUpperCase() + sName.slice(1) + " shell";
                }
                if (parts[1]) root.shellVersion = parts[1];
            }
        }
    }

    Process {
        id: quickshellProc
        command: ["qs", "--version"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.trim().match(/^(Quickshell\s+[\d.]+)/);
                if (match) root.quickshellVersion = match[1];
            }
        }
    }

    Process {
        id: identityProc
        command: ["sh", "-c", "echo \"$(whoami)|$(hostname)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts[0]) root.username = parts[0];
                if (parts[1]) root.hostname = parts[1];
            }
        }
    }

    FileView {
        id: fileSessionType
        path: "/proc/self/environ"
        onTextChanged: {
            const text = fileSessionType.text();
            if (!text) return;
            const vars = {};
            text.split("\0").forEach(entry => {
                const idx = entry.indexOf("=");
                if (idx !== -1) vars[entry.slice(0, idx)] = entry.slice(idx + 1);
            });

            const compositor = vars["HYPRLAND_INSTANCE_SIGNATURE"] ? "Hyprland" : vars["SWAYSOCK"] ? "Sway" : vars["DISPLAY"] && !vars["WAYLAND_DISPLAY"] ? "X11" : vars["COMPOSITOR_NAME"] ?? "";
            const type = vars["WAYLAND_DISPLAY"] ? "Wayland" : vars["DISPLAY"] ? "X11" : "unknown";
            root.session = compositor ? compositor + " + " + type : type;
        }
    }

    FileView {
        id: fileOsRelease
        path: "/etc/os-release"
        onTextChanged: {
            const text = fileOsRelease.text();
            if (!text) return;

            const prettyMatch = text.match(/^PRETTY_NAME="(.+?)"/m);
            const nameMatch = text.match(/^NAME="(.+?)"/m);
            root.distroName = prettyMatch ? prettyMatch[1] : nameMatch ? nameMatch[1] : "Linux";

            const idMatch = text.match(/^ID="?(.+?)"?$/m);
            root.distroId = idMatch ? idMatch[1].toLowerCase() : "unknown";

            const logoMatch = text.match(/^LOGO="?(.+?)"?$/m);
            if (logoMatch && logoMatch[1].trim().length > 0) {
                root.logo = logoMatch[1].trim();
            } else {
                root.logo = "distributor-logo-" + root.distroId;
            }
        }
    }

    FileView {
        id: fileUptime
        path: "/proc/uptime"
        onTextChanged: {
            const content = fileUptime.text();
            if (!content) return;
            const rawSecs = content.split(" ")[0];
            root.uptime = formatUptime(parseFloat(rawSecs));
        }
    }
}