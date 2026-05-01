pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string distroName: "Linux"
    property string distroId: "unknown"
    property string logo: "linux-symbolic"
    property string username: "user"
    property string hostname: "localhost"
    property string uptime: "unknown"

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

        return "up " + parts.join(" ");
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            usernameProc.running = true;
            hostnameProc.running = true;
            fileOsRelease.reload();
            fileUptime.reload();
        }
    }

    Process {
        id: usernameProc
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => root.username = data.trim()
        }
    }

    Process {
        id: hostnameProc
        command: ["hostname"]
        stdout: SplitParser {
            onRead: data => root.hostname = data.trim()
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
            const logoField = logoMatch ? logoMatch[1].trim() : "";

            if (logoField.length > 0) {
                root.logo = logoField;
            } else {
                switch (root.distroId) {
                case "arch":
                case "artix":
                    root.logo = "arch-symbolic";
                    break;
                case "endeavouros":
                    root.logo = "endeavouros-symbolic";
                    break;
                case "cachyos":
                    root.logo = "cachyos-symbolic";
                    break;
                case "nixos":
                    root.logo = "nixos-symbolic";
                    break;
                case "fedora":
                    root.logo = "fedora-symbolic";
                    break;
                case "ubuntu":
                case "linuxmint":
                case "popos":
                case "zorin":
                    root.logo = "ubuntu-symbolic";
                    break;
                case "debian":
                case "kali":
                case "raspbian":
                    root.logo = "debian-symbolic";
                    break;
                case "gentoo":
                case "funtoo":
                    root.logo = "gentoo-symbolic";
                    break;
                default:
                    root.logo = "linux-symbolic";
                    break;
                }
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
