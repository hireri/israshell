import QtQuick
import qs.style
import qs.services

Tile {
    id: root

    property alias checkId: source.checkId
    readonly property alias info: source

    CheckInfo {
        id: source
    }

    visible: source.live
    label: source.label
    sublabel: source.text
    tone: source.tone === "ok" ? "neutral" : source.tone
}
