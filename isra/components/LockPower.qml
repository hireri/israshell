import QtQuick
import Quickshell
import qs.style

Item {
    id: root

    property bool compact: false
    property bool opensUp: false
    property bool open: false
    property int pending: -1

    readonly property var entries: [
        { label: Localization.t("lockSurface.log_out"), icon: "logout", command: ["sh", "-c", "loginctl terminate-user \"$USER\""] },
        { label: Localization.t("lockSurface.restart"), icon: "reboot", command: ["sh", "-c", "systemctl reboot || loginctl reboot"] },
        { label: Localization.t("lockSurface.shut_down"), icon: "shutdown", command: ["sh", "-c", "systemctl poweroff || loginctl poweroff"] }
    ]

    readonly property var menuEntries: pending < 0
        ? entries.map(e => ({ label: e.label, icon: e.icon }))
        : [
            { label: entries[pending].label + "?", header: true },
            { label: Localization.t("lockSurface.confirm"), icon: "check", danger: true },
            { label: Localization.t("lockSurface.cancel"), icon: "close" }
        ]

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function close() {
        open = false;
        pending = -1;
    }

    onPendingChanged: autoClose.restart()

    Timer {
        id: autoClose
        interval: 8000
        running: root.open
        onTriggered: root.close()
    }

    LockButton {
        id: button
        size: root.compact ? 44 : 40
        icon: "shutdown"
        label: root.compact ? "" : Localization.t("lockSurface.power")
        trailing: root.compact ? "" : "keyboard-arrow-down"
        trailingFlipped: root.opensUp !== root.open
        container: Colors.md3.surface_container_high
        content: Colors.md3.on_surface
        onClicked: root.open ? root.close() : root.open = true
    }

    LockMenu {
        anchors {
            right: root.right
            bottom: root.opensUp ? root.top : undefined
            top: root.opensUp ? undefined : root.bottom
            bottomMargin: 8
            topMargin: 8
        }
        entries: root.menuEntries
        open: root.open
        opensUp: root.opensUp
        onTriggered: i => {
            if (root.pending < 0) {
                root.pending = i;
            } else if (i === 1) {
                Quickshell.execDetached(root.entries[root.pending].command);
                root.close();
            } else {
                root.pending = -1;
            }
        }
    }
}
