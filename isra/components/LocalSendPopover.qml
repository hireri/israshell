import QtQuick
import Qt.labs.platform as Labs
import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow
    required property var widgetItem
    property var controllerRegistry: null

    readonly property string panelType: "localsend"

    readonly property bool isOpen: root._isOpen
    property bool _isOpen: false

    function open() {
        _isOpen = true;
        PanelService.opened(root, root.panelWindow.screen);
        LocalSendService.scanNow();
    }

    function close() {
        if (!root._isOpen)
            return;
        _isOpen = false;
        PanelService.closed(root);
    }

    function openFilePicker(): void {
        filePicker.open();
    }

    Component.onCompleted: {
        if (root.controllerRegistry)
            root.controllerRegistry[root.panelType] = root;
    }

    Labs.FileDialog {
        id: filePicker
        title: Localization.t("localSendPopover.choose_files_to_send")
        fileMode: Labs.FileDialog.OpenFiles
        onAccepted: {
            LocalSendService.attachFilesFromUrls(filePicker.files);
            root.open();
        }
        onRejected: root.open()
    }
}
