import QtQuick
import qs.style
import qs.services
import qs.windows
import qs.windows.components

Row {
    id: root

    property string checkId: ""
    property string target: ""

    spacing: 8

    ActionButton {
        visible: root.checkId.startsWith("updates.")
        icon: "download-for-offline"
        label: Localization.t("systemApp.update_all")
        onClicked: HealthService.runAction("update", "")
    }

    ActionButton {
        visible: root.checkId === "pkg.orphans"
        icon: "delete"
        label: Localization.t("systemApp.remove")
        onClicked: HealthService.runAction("removeOrphans", "")
    }

    ActionButton {
        visible: root.checkId === "pkg.pacnew"
        icon: "open-with"
        label: Localization.t("systemApp.review")
        onClicked: HealthService.runAction("pacdiff", "")
    }

    ActionButton {
        visible: root.checkId === "pkg.cache"
        icon: "clear-all"
        label: Localization.t("systemApp.clean")
        onClicked: HealthService.runAction("cleanCache", "")
    }

    ActionButton {
        visible: root.checkId === "sys.reboot"
        danger: true
        icon: "reboot"
        label: Localization.t("systemApp.reboot")
        onClicked: HealthService.runAction("reboot", "")
    }

    ActionButton {
        visible: !root.checkId.startsWith("updates.") && ["pkg.orphans", "pkg.pacnew", "pkg.cache", "sys.reboot"].indexOf(root.checkId) < 0
        icon: "arrow-forward"
        label: Localization.t("systemApp.open")
        onClicked: SystemPages.openPage(root.target)
    }
}
