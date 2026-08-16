import QtQuick
import Qt.labs.platform as Labs
import qs.style
import qs.services
import qs.components.widgetsettings
import qs.icons

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.photo")
    sizeMode: "uniform"
    minSpan: ({ w: 1, h: 1 })
    maxSpan: ({ w: 8, h: 8 })
    defaultSize: 200
    minSize: 48

    property real _sourceSizeAnchor: 200
    function _syncSourceAnchor(): void {
        if (!shell._interacting)
            shell._sourceSizeAnchor = shell.localSize;
    }
    onLocalSizeChanged: shell._syncSourceAnchor()
    on_InteractingChanged: shell._syncSourceAnchor()

    readonly property string shapeName: shell.entryData.shape || "circle"

    function pickImage(): void {
        filePicker.open();
    }

    settingsPanel: Component {
        PhotoSettings {
            entryId: shell.entryId
        }
    }

    extraMenuEntries: [
        {
            text: Localization.t("widgetMenu.change_image"),
            icon: imageIconComp,
            action: () => shell.pickImage()
        }
    ]

    PhotoVisual {
        anchors.fill: parent
        shape: shell.shapeName
        imagePath: shell.entryData.imagePath ?? ""
        sourceSizeAnchor: shell._sourceSizeAnchor

        MouseArea {
            anchors.fill: parent
            enabled: !EditModeService.active
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.pickImage()
        }
    }

    Labs.FileDialog {
        id: filePicker
        title: "Choose photo"
        fileMode: Labs.FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.gif *.bmp)", "All files (*)"]
        onAccepted: {
            const path = decodeURIComponent(filePicker.file.toString().replace(/^file:\/\//, ""));
            DesktopWidgetService.updateEntryData(shell.entryId, { imagePath: path });
        }
    }

    Component {
        id: imageIconComp
        MaterialIcon {
            name: "image"
            iconSize: 16
        }
    }
}
