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

    function formatUptime(seconds) {
        let s = Math.floor(seconds);
        let d = Math.floor(s / 86400);
        s %= 86400;
        let h = Math.floor(s / 3600);
        s %= 3600;
        let m = Math.floor(s / 60);
        let parts = [];
        if (d > 0)
            parts.push(d + "d");
        if (h > 0)
            parts.push(h + "h");
        if (m > 0 || parts.length === 0)
            parts.push(m + "m");
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
                console.log("Hardware raw:", data.trim());
                if (parts[0] && parts[0] !== "Unknown")
                    root.cpu = parts[0];
                if (parts[1] && parts[1] !== "Unknown GPU" && parts[1] !== "")
                    root.gpu = parts[1];
                if (parts[2] && parts[2] !== "Unknown") {
                    root.memory = parts[2].toUpperCase().replace("I", "i") + "B RAM";
                }
                if (parts[3] && parts[3] !== "Unknown" && parts[3] !== "")
                    root.motherboard = parts[3];
            }
        }
        stderr: SplitParser {
            onRead: data => console.warn("Hardware stderr:", data.trim())
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
                if (parts[1])
                    root.shellVersion = parts[1];
            }
        }
    }

    Process {
        id: quickshellProc
        command: ["qs", "--version"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.trim().match(/^(Quickshell\s+[\d.]+)/);
                if (match)
                    root.quickshellVersion = match[1];
            }
        }
    }

    Process {
        id: identityProc
        command: ["sh", "-c", "echo \"$(whoami)|$(hostname)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts[0])
                    root.username = parts[0];
                if (parts[1])
                    root.hostname = parts[1];
            }
        }
    }

    FileView {
        id: fileSessionType
        path: "/proc/self/environ"
        onTextChanged: {
            const text = fileSessionType.text();
            if (!text)
                return;
            const vars = {};
            text.split("\0").forEach(entry => {
                const idx = entry.indexOf("=");
                if (idx !== -1)
                    vars[entry.slice(0, idx)] = entry.slice(idx + 1);
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
            if (!text)
                return;

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
            if (!content)
                return;
            const rawSecs = content.split(" ")[0];
            root.uptime = formatUptime(parseFloat(rawSecs));
        }
    }
}
