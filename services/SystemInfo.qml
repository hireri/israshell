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

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            usernameProc.running = true;
            hostnameProc.running = true;
            fileOsRelease.reload();
            const text = fileOsRelease.text();

            const prettyMatch = text.match(/^PRETTY_NAME="(.+?)"/m);
            const nameMatch = text.match(/^NAME="(.+?)"/m);
            distroName = prettyMatch ? prettyMatch[1] : nameMatch ? nameMatch[1] : "Linux";

            const idMatch = text.match(/^ID="?(.+?)"?$/m);
            distroId = idMatch ? idMatch[1].toLowerCase() : "unknown";

            const logoMatch = text.match(/^LOGO="?(.+?)"?$/m);
            const logoField = logoMatch ? logoMatch[1].trim() : "";

            if (logoField.length > 0) {
                logo = logoField;
            } else {
                switch (distroId) {
                case "arch":
                case "artix":
                    logo = "arch-symbolic";
                    break;
                case "endeavouros":
                    logo = "endeavouros-symbolic";
                    break;
                case "cachyos":
                    logo = "cachyos-symbolic";
                    break;
                case "nixos":
                    logo = "nixos-symbolic";
                    break;
                case "fedora":
                    logo = "fedora-symbolic";
                    break;
                case "ubuntu":
                case "linuxmint":
                case "popos":
                case "zorin":
                    logo = "ubuntu-symbolic";
                    break;
                case "debian":
                case "kali":
                case "raspbian":
                    logo = "debian-symbolic";
                    break;
                case "gentoo":
                case "funtoo":
                    logo = "gentoo-symbolic";
                    break;
                default:
                    logo = "linux-symbolic";
                    break;
                }
            }
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
    }
}
