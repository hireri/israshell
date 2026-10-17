import QtQuick
import qs.style

ListRow {
    id: root

    property alias checkId: info.checkId

    CheckInfo {
        id: info
    }

    title: info.label
    sublabel: info.text
}
