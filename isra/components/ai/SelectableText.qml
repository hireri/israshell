import QtQuick
import qs.style
import qs.services

TextEdit {
    id: root

    readOnly: true
    selectByMouse: true
    persistentSelection: true
    activeFocusOnPress: false
    cursorVisible: false
    wrapMode: TextEdit.Wrap
    selectionColor: Qt.alpha(Colors.md3.primary, 0.35)
    selectedTextColor: root.color
    font.family: Config.fontFamily

    onSelectedTextChanged: AiAssistantService.reportSelection(root, root.selectedText)
    onLinkActivated: link => Qt.openUrlExternally(link)
    Component.onDestruction: AiAssistantService.reportSelection(root, "")

    HoverHandler {
        cursorShape: root.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.IBeamCursor
    }
}
