pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.components
import qs.windows.components

PageBase {
    id: page

    pageId: "powermenu"
    title: Localization.t("powerMenuPage.title")
    subtitle: Localization.t("powerMenuPage.subtitle")

    property int editIndex: -1
    property bool formOpen: false
    property bool resetArmed: false
    property var draft: ({ label: "", command: "", key: "", icon: "scripts", hold: false })

    readonly property var raw: Config.powerMenu?.entries ?? []
    readonly property var available: PowerMenuService.catalogIds.filter(id => !page.raw.some(e => e.id === id))
    readonly property bool formValid: page.draft.label.trim() !== "" && page.draft.command.trim() !== ""

    function _save(list) {
        Config.update({ powerMenu: { entries: list } });
    }

    function setField(field, value) {
        if (page.draft[field] === value)
            return;
        const d = Object.assign({}, page.draft);
        d[field] = value;
        page.draft = d;
    }

    function move(i, d) {
        const j = i + d;
        if (j < 0 || j >= page.raw.length)
            return;
        const list = page.raw.slice();
        [list[i], list[j]] = [list[j], list[i]];
        page._save(list);
        if (page.formOpen && page.editIndex === i)
            page.editIndex = j;
        else if (page.formOpen && page.editIndex === j)
            page.editIndex = i;
    }

    function removeAt(i) {
        const list = page.raw.slice();
        list.splice(i, 1);
        page._save(list);
        if (page.formOpen && page.editIndex === i)
            page.formOpen = false;
        else if (page.formOpen && page.editIndex > i)
            page.editIndex -= 1;
    }

    function addBuiltin(id) {
        page._save([...page.raw, { id: id }]);
    }

    function openForm(i) {
        const e = i >= 0 ? page.raw[i] : null;
        page.editIndex = i;
        page.draft = {
            label: e?.label ?? "",
            command: e?.command ?? "",
            key: e?.key ?? "",
            icon: e?.icon ?? "scripts",
            hold: e?.hold ?? false
        };
        page.formOpen = true;
    }

    function closeForm() {
        page.formOpen = false;
    }

    function saveForm() {
        if (!page.formValid)
            return;
        const d = page.draft;
        const list = page.raw.slice();
        const prev = page.editIndex >= 0 ? page.raw[page.editIndex] : null;
        const entry = {
            id: prev ? prev.id : "custom-" + Date.now().toString(36),
            label: d.label.trim(),
            icon: d.icon,
            command: d.command.trim(),
            key: d.key.trim().toUpperCase().charAt(0),
            hold: d.hold
        };
        if (prev)
            list[page.editIndex] = entry;
        else
            list.push(entry);
        page._save(list);
        page.formOpen = false;
    }

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: page.resetArmed = false
    }

    component IconBtn: Rectangle {
        id: btn
        property string icon
        property string tip: ""
        property bool dim: false
        property string confirmText: ""
        property bool armed: false
        signal clicked

        implicitWidth: btn.armed ? armRow.implicitWidth + 20 : 32
        implicitHeight: 32
        radius: 16
        color: btn.armed ? Colors.md3.error_container : (btnMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)
        opacity: btn.dim ? 0.35 : 1

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: armRow
            anchors.centerIn: parent
            spacing: 6

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: btn.icon
                iconSize: 18
                color: btn.armed ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
                transitionType: "none"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: btn.armed
                text: btn.confirmText
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Colors.md3.on_error_container
            }
        }

        Timer {
            id: disarm
            interval: 3000
            onTriggered: btn.armed = false
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: !btn.dim
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (btn.confirmText === "" || btn.armed) {
                    disarm.stop();
                    btn.armed = false;
                    btn.clicked();
                } else {
                    btn.armed = true;
                    disarm.restart();
                }
            }
        }

        Tooltip {
            text: btn.armed ? "" : btn.tip
        }
    }

    SectionCard {
        label: Localization.t("powerMenuPage.entries")
        Layout.fillWidth: true

        Item {
            visible: page.raw.length === 0
            implicitWidth: parent?.width ?? 0
            implicitHeight: 56

            Text {
                anchors.centerIn: parent
                text: Localization.t("powerMenuPage.empty")
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.outline
            }
        }

        Repeater {
            model: PowerMenuService.entries

            delegate: Item {
                id: row
                required property var modelData
                required property int index

                readonly property bool open: page.formOpen && page.editIndex === row.index

                implicitWidth: parent?.width ?? 0
                implicitHeight: header.height + form.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 14
                    color: Config.dim(Colors.md3.surface_container_high)
                    opacity: row.open ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                Item {
                    id: header
                    width: parent.width
                    height: 56

                    Rectangle {
                        id: badge
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        radius: 17
                        color: Colors.md3.primary_container

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: row.open ? page.draft.icon : row.modelData.icon
                            iconSize: 18
                            filled: true
                            color: Colors.md3.on_primary_container
                            transitionType: "none"
                        }
                    }

                    Column {
                        anchors.left: badge.right
                        anchors.leftMargin: 14
                        anchors.right: buttons.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            readonly property string title: row.open ? (page.draft.label.trim() || Localization.t("powerMenuPage.new_entry")) : row.modelData.text
                            readonly property string key: row.open ? page.draft.key.toUpperCase() : row.modelData.key

                            width: parent.width
                            text: title + (key !== "" ? "  ·  " + key : "")
                            elide: Text.ElideRight
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Colors.md3.on_surface
                        }

                        Text {
                            width: parent.width
                            text: row.modelData.builtin ? Localization.t("powerMenuPage.builtin") : (row.open ? page.draft.command : row.modelData.command)
                            elide: Text.ElideRight
                            font.family: row.modelData.builtin ? Config.fontFamily : Config.fontMonospace
                            font.pixelSize: 11
                            color: Colors.md3.outline
                        }
                    }

                    Row {
                        id: buttons
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        IconBtn {
                            icon: "arrow-upward"
                            tip: Localization.t("powerMenuPage.move_up")
                            dim: row.index === 0
                            onClicked: page.move(row.index, -1)
                        }

                        IconBtn {
                            icon: "arrow-downward"
                            tip: Localization.t("powerMenuPage.move_down")
                            dim: row.index === PowerMenuService.entries.length - 1
                            onClicked: page.move(row.index, 1)
                        }

                        IconBtn {
                            visible: !row.modelData.builtin
                            icon: row.open ? "close" : "edit"
                            tip: Localization.t("powerMenuPage.edit")
                            onClicked: row.open ? page.closeForm() : page.openForm(row.index)
                        }

                        IconBtn {
                            icon: "delete"
                            tip: Localization.t("powerMenuPage.remove")
                            confirmText: row.modelData.builtin ? "" : Localization.t("powerMenuPage.confirm_remove")
                            onClicked: page.removeAt(row.index)
                        }
                    }
                }

                PowerEntryForm {
                    id: form
                    anchors.top: header.bottom
                    width: parent.width
                    open: row.open
                    draft: page.draft
                    valid: page.formValid
                    onEdited: (f, v) => page.setField(f, v)
                    onSaved: page.saveForm()
                    onCancelled: page.closeForm()
                    onRevealRequested: h => page.reveal(row, header.height + h)
                }

                Rectangle {
                    visible: !row.open
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }
        }

        SettingActions {
            isLast: true
            label: Localization.t("powerMenuPage.add_entry")
            sublabel: Localization.t("powerMenuPage.add_entry_sub")

            Repeater {
                model: page.available

                delegate: ActionButton {
                    required property string modelData
                    icon: "add"
                    label: Localization.t(PowerMenuService.catalog[modelData].labelKey)
                    onClicked: page.addBuiltin(modelData)
                }
            }

            ActionButton {
                icon: "add"
                label: Localization.t("powerMenuPage.custom")
                onClicked: draftForm.open ? page.closeForm() : page.openForm(-1)
            }
        }

        PowerEntryForm {
            id: draftForm
            topRule: true
            open: page.formOpen && page.editIndex === -1
            draft: page.draft
            valid: page.formValid
            onEdited: (f, v) => page.setField(f, v)
            onSaved: page.saveForm()
            onCancelled: page.closeForm()
            onRevealRequested: h => page.reveal(draftForm, h)
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingActions {
            isLast: true
            label: Localization.t("powerMenuPage.reset")
            sublabel: Localization.t("powerMenuPage.reset_sub")

            ActionButton {
                icon: "restart"
                danger: page.resetArmed
                label: Localization.t(page.resetArmed ? "powerMenuPage.reset_confirm" : "powerMenuPage.reset")
                onClicked: {
                    if (!page.resetArmed) {
                        page.resetArmed = true;
                        resetTimer.restart();
                        return;
                    }
                    resetTimer.stop();
                    page.resetArmed = false;
                    page.formOpen = false;
                    Config.update({ powerMenu: Config.__defaults().powerMenu });
                }
            }
        }
    }
}
