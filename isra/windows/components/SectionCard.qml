import QtQuick
import qs.style

Column {
    id: root

    property string label: ""
    spacing: 0

    Text {
        text: root.label
        font.family: Config.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
        color: Colors.md3.primary
        font.letterSpacing: 0.7
        visible: root.label !== ""
        topPadding: 4
        bottomPadding: 6
        leftPadding: 2
    }

    Rectangle {
        id: card
        width: root.width
        height: cardColumn.implicitHeight
        color: Colors.md3.surface_container
        radius: 18

        Column {
            id: cardColumn
            width: parent.width
            onChildrenChanged: Qt.callLater(root._updateDividers)
        }
    }

    default property alias items: cardColumn.data

    Component.onCompleted: Qt.callLater(_updateDividers)

    function _updateDividers() {
        const rows = [];
        const kids = cardColumn.children;
        for (let i = 0; i < kids.length; i++) {
            const k = kids[i];
            if (typeof k.itemAt === "function") {
                for (let j = 0; j < k.count; j++) {
                    const item = k.itemAt(j);
                    if (item && item.hasOwnProperty("isLast"))
                        rows.push(item);
                }
            } else if (k.hasOwnProperty("isLast")) {
                rows.push(k);
            }
        }
        for (let i = 0; i < rows.length; i++)
            rows[i].isLast = (i === rows.length - 1);
    }
}
