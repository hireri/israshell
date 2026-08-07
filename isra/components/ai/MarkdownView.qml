pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style
import "markdown.js" as Markdown

ColumnLayout {
    id: root

    property string text: ""
    property color textColor: Colors.md3.on_surface
    property real fontSize: 15
    property real maxWidth: 600

    spacing: 0

    onTextChanged: root._sync()
    Component.onCompleted: root._sync()

    function _sync(): void {
        const blocks = Markdown.parseBlocks(root.text);

        for (let i = 0; i < blocks.length; i++) {
            const b = blocks[i];
            if (i < blockModel.count) {
                const cur = blockModel.get(i);
                if (cur.type === b.type && cur.lang === b.lang) {
                    if (cur.text !== b.text)
                        blockModel.setProperty(i, "text", b.text);
                    if (cur.open !== b.open)
                        blockModel.setProperty(i, "open", b.open);
                    continue;
                }
                blockModel.set(i, b);
                continue;
            }
            blockModel.append(b);
        }

        while (blockModel.count > blocks.length)
            blockModel.remove(blockModel.count - 1);
    }

    ListModel {
        id: blockModel
    }

    Repeater {
        model: blockModel

        Loader {
            id: blockLoader

            required property int index
            required property string type
            required property string text
            required property string lang
            required property bool open

            readonly property bool _looseGap: blockLoader.type !== "prose" || (blockLoader.index > 0 && blockModel.get(blockLoader.index - 1).type !== "prose")
            Layout.topMargin: blockLoader.index === 0 ? 0 : (blockLoader._looseGap ? 24 : 12)
            Layout.maximumWidth: root.maxWidth

            sourceComponent: {
                if (blockLoader.type === "code")
                    return codeComp;
                if (blockLoader.type === "table")
                    return tableComp;
                if (blockLoader.type === "quote")
                    return quoteComp;
                return proseComp;
            }

            onLoaded: {
                item.body = Qt.binding(() => blockLoader.text);
                if (blockLoader.type === "code") {
                    item.lang = Qt.binding(() => blockLoader.lang);
                    item.open = Qt.binding(() => blockLoader.open);
                }
            }
        }
    }

    Component {
        id: proseComp

        Text {
            property string body: ""

            text: body
            textFormat: Text.MarkdownText
            wrapMode: Text.Wrap
            color: root.textColor
            linkColor: Colors.md3.primary
            font.pixelSize: root.fontSize
            font.family: Config.fontFamily
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
    }

    Component {
        id: codeComp

        CodeBlock {
            maxWidth: root.maxWidth
            fontSize: root.fontSize - 2
        }
    }

    Component {
        id: tableComp

        MdTable {
            maxWidth: root.maxWidth
            fontSize: root.fontSize - 1
        }
    }

    Component {
        id: quoteComp

        QuoteBlock {
            maxWidth: root.maxWidth
            fontSize: root.fontSize
        }
    }
}
