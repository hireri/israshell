pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.style
import qs.icons
import "markdown.js" as Markdown
import "syntax.js" as Syntax

Rectangle {
    id: root

    property string body: ""
    property string lang: ""
    property bool open: false
    property real maxWidth: 600
    property real fontSize: 13

    readonly property string label: Markdown.langLabel(root.lang)

    function _tone(hueShift: real): string {
        const base = Qt.color(Colors.md3.primary).hslHue;
        let h = base + hueShift;
        h -= Math.floor(h);
        return Qt.hsla(h, Config.darkMode ? 0.52 : 0.62, Config.darkMode ? 0.72 : 0.36, 1).toString();
    }

    readonly property var palette: ({
        keyword: _tone(0.0),
        func: _tone(0.11),
        string: _tone(0.33),
        number: _tone(0.55),
        type: _tone(0.78),
        comment: Qt.alpha(Colors.md3.on_surface_variant, 0.8).toString()
    })

    readonly property bool overflows: codeViewport.contentWidth > codeViewport.width + 1

    readonly property real headerMinWidth: headerRow.implicitWidth + copyBtn.width + 12 + 16 + 6

    implicitWidth: Math.min(Math.max(codeText.implicitWidth + 24, root.headerMinWidth, 120), root.maxWidth)
    implicitHeight: header.height + codeViewport.height + 12 + (overflows ? scrollbar.height + 4 : 0)

    radius: 12
    color: Qt.alpha(Colors.md3.surface_container_low, Config.blurOpacity)
    border.width: 1
    border.color: Colors.md3.outline_variant
    clip: true

    Process {
        id: copyProc
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34

        Row {
            id: headerRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                visible: text !== ""
                color: Colors.md3.on_surface_variant
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: Config.fontFamily
            }
        }

        Rectangle {
            id: copyBtn

            visible: !root.open
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: copyRow.implicitWidth + 16
            height: 22
            radius: 11

            property bool copied: false
            readonly property color containerColor: copyBtn.copied ? Colors.md3.primary_container : Colors.md3.secondary_container
            readonly property color contentColor: copyBtn.copied ? Colors.md3.on_primary_container : Colors.md3.on_secondary_container

            color: Qt.tint(copyBtn.containerColor, Qt.alpha(copyBtn.contentColor, copyMa.containsMouse ? 0.08 : 0))

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Row {
                id: copyRow
                anchors.centerIn: parent
                spacing: 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: copyBtn.copied ? "check" : "copy"
                    iconSize: 13
                    transitionType: "none"
                    color: copyBtn.contentColor
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: copyBtn.copied ? Localization.t("aiAssistant.copied") : Localization.t("aiAssistant.copy")
                    color: copyBtn.contentColor
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }
            }

            Timer {
                id: copiedReset
                interval: 1600
                onTriggered: copyBtn.copied = false
            }

            MouseArea {
                id: copyMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    copyProc.command = ["wl-copy", root.body];
                    copyProc.running = true;
                    copyBtn.copied = true;
                    copiedReset.restart();
                }
            }
        }
    }

    Item {
        id: codeViewport
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: codeText.implicitHeight
        clip: true

        property real contentX: 0
        readonly property real contentWidth: codeText.implicitWidth

        onContentWidthChanged: contentX = Math.max(0, Math.min(contentX, Math.max(0, contentWidth - width)))
        onWidthChanged: contentX = Math.max(0, Math.min(contentX, Math.max(0, contentWidth - width)))

        function _followCursor(): void {
            if (!root.overflows)
                return;
            const margin = 16;
            const cursorX = codeText.cursorRectangle.x;
            if (cursorX - codeViewport.contentX < margin)
                codeViewport.contentX = Math.max(0, cursorX - margin);
            else if (cursorX - codeViewport.contentX > codeViewport.width - margin)
                codeViewport.contentX = Math.min(codeViewport.contentWidth - codeViewport.width, cursorX - codeViewport.width + margin);
        }

        TextEdit {
            id: codeText
            x: -codeViewport.contentX
            text: "<div style=\"line-height:135%\">" + Syntax.highlight(root.body, root.lang, root.palette) + "</div>"
            textFormat: TextEdit.RichText
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            cursorVisible: false
            activeFocusOnPress: false
            color: Colors.md3.on_surface
            selectionColor: Qt.alpha(Colors.md3.primary, 0.35)
            selectedTextColor: Colors.md3.on_surface
            font.pixelSize: root.fontSize
            font.family: Config.fontMonospace
            onCursorRectangleChanged: codeViewport._followCursor()

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }
        }
    }

    HScrollBar {
        id: scrollbar
        visible: root.overflows
        anchors.top: codeViewport.bottom
        anchors.topMargin: 4
        anchors.left: codeViewport.left
        anchors.right: codeViewport.right
        contentX: codeViewport.contentX
        contentWidth: codeViewport.contentWidth
        viewWidth: codeViewport.width
        onSeek: newContentX => codeViewport.contentX = newContentX
    }
}
