import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string iconSource: ""
    property color iconBg: Colors.md3.primary_container
    property string label: ""
    property string sublabel: ""

    property bool isLast: {
        if (!parent)
            return false;
        const siblings = parent.children;
        let lastVisible = null;
        for (let i = siblings.length - 1; i >= 0; i--) {
            if (siblings[i].visible !== false) {
                lastVisible = siblings[i];
                break;
            }
        }
        return lastVisible === this;
    }

    default property alias content: trailingSlot.data

    implicitHeight: Math.max(56, contentRow.implicitHeight + 20)
    implicitWidth: parent?.width ?? 0

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        height: 1
        color: Colors.md3.outline_variant
        visible: !root.isLast
        opacity: 0.5
    }

    RowLayout {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 18
            rightMargin: 18
        }
        spacing: 14
        y: (root.implicitHeight - implicitHeight) / 2

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: root.iconBg
            visible: root.iconSource !== ""
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.centerIn: parent
                source: root.iconSource
                width: 18
                height: 18
                smooth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            visible: root.label !== ""

            Text {
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.on_surface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.outline
                visible: root.sublabel !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Item {
            id: trailingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
