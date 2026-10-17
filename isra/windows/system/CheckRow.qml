import QtQuick
import qs.style
import qs.services
import qs.windows.components

SettingRow {
    id: root

    property alias checkId: info.checkId
    property alias detail: info.detail

    readonly property var res: info.res
    readonly property string sev: info.sev
    readonly property bool live: info.live

    CheckInfo {
        id: info
    }

    visible: root.live
    label: info.label
    sublabel: info.text

    StatusTag {
        text: info.res ? Localization.t("systemApp.sev_" + info.sev) : Localization.t("systemApp.sev_checking")
        tone: info.tone
    }
}
