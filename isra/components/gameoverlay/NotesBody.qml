pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.style
import qs.windows.components

Item {
    id: root

    property string text
    property bool dirty: false
    property int copied: -1

    readonly property var bullets: root.text.split("\n").map(l => /^\s*-\s+(.*\S)\s*$/.exec(l)?.[1]).filter(b => b).slice(0, 12)

    implicitWidth: 320
    implicitHeight: 260

    function save() {
        saveTimer.stop();
        if (!root.dirty)
            return;
        notesFile.setText(root.text);
        root.dirty = false;
    }

    Component.onDestruction: root.save()

    FileView {
        id: notesFile
        path: Config.configDir + "/overlay-notes.txt"
        blockLoading: true
        watchChanges: false
        printErrors: false

        Component.onCompleted: {
            try {
                root.text = notesFile.text();
            } catch (e) {}
        }
    }

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: root.save()
    }

    Timer {
        id: copiedTimer
        interval: 1200
        onTriggered: root.copied = -1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        TextAreaField {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120
            flat: true
            fontSize: 13
            commitOnReturn: false
            text: root.text
            placeholder: Localization.t("gameOverlay.notes_placeholder")
            onEdited: t => {
                root.text = t;
                root.dirty = true;
                saveTimer.restart();
            }
            onCommitted: root.save()
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.bullets.length > 0

            Repeater {
                model: root.bullets

                delegate: OverlayButton {
                    required property string modelData
                    required property int index

                    size: 28
                    icon: root.copied === index ? "check" : "copy"
                    label: modelData.length > 24 ? modelData.slice(0, 23) + "…" : modelData
                    tip: modelData
                    toggled: root.copied === index
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", "--", modelData]);
                        root.copied = index;
                        copiedTimer.restart();
                    }
                }
            }
        }
    }
}
