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
    readonly property string _image: {
        if (groupRef && groupRef._isAvatarMode)
            return "";
        return msgData?.image ?? "";
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
        spacing: 6

        ClippingRectangle {
            id: attachmentRect
            Layout.fillWidth: true
            visible: !item.collapsed && item._image.length > 0
            radius: 12
            color: Colors.md3.surface_container

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
                source: item._image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: item._md(item._body.length > 0 ? item._body : item._summary)
            color: Colors.md3.on_surface_variant
            font.family: Config.fontFamily
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            maximumLineCount: item.collapsed ? 2 : -1
            elide: item.collapsed ? Text.ElideRight : Text.ElideNone
        }
    }

    function _md(s) {
        if (!s)
            return "";
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/<img[^>]*>/g, "").replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(.+?)\*/g, "<i>$1</i>").replace(/~~(.+?)~~/g, "<s>$1</s>").replace(/`(.+?)`/g, "<tt>$1</tt>").replace(/\n/g, "<br/>");
    }
}
