pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.style

Item {
    id: item

    property var msgData: null
    property var groupRef: null
    property int itemIndex: 0
    property bool collapsed: false

    readonly property string _body: msgData?.body ?? ""
    readonly property string _summary: msgData?.summary ?? ""

    readonly property string _inlineImage: {
        if (!groupRef)
            return "";
        const img = groupRef.getBodyImage(_body);
        if (img === "")
            return "";

        if (img.startsWith("/") || img.includes("://"))
            return img;
        return Quickshell.iconPath(img, "");
    }

    readonly property string _displayText: {
        if (!groupRef)
            return _body || _summary;
        return groupRef._md(_body.length > 0 ? _body : _summary);
    }

    Component.onCompleted: {
        if (groupRef !== null && !collapsed) {
            item.x = 16;
            slideIn.start();
        }
    }

    NumberAnimation {
        id: slideIn
        target: item
        property: "x"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
    }

    implicitWidth: parent ? parent.width : 300
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: item._displayText
            color: Colors.md3.on_surface_variant
            font.family: Config.fontFamily
            font.pixelSize: 13
            wrapMode: Text.WordWrap

            textFormat: Text.StyledText

            onLinkActivated: link => Qt.openUrlExternally(link)

            maximumLineCount: item.collapsed ? 2 : -1
            elide: item.collapsed ? Text.ElideRight : Text.ElideNone
        }

        ClippingRectangle {
            id: attachmentRect
            Layout.fillWidth: true
            visible: !item.collapsed && item._inlineImage !== ""
            radius: 12
            color: Colors.md3.surface_container_lowest
            clip: true

            Layout.preferredHeight: {
                if (attachmentImg.implicitWidth > 0) {
                    let h = width * (attachmentImg.implicitHeight / attachmentImg.implicitWidth);
                    return Math.min(h, 220);
                }
                return 160;
            }

            Image {
                id: attachmentImg
                anchors.fill: parent
                source: item._inlineImage
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                autoTransform: true
            }
        }
    }
}
