pragma ComponentBehavior: Bound

import QtQuick
import qs.style

Item {
    id: root

    property bool open: false
    property bool topRule: false
    property var draft: ({})
    property bool valid: false
    readonly property real bodyHeight: loader.item ? (loader.item as Item).implicitHeight : 0

    signal edited(string field, var value)
    signal saved
    signal cancelled
    signal revealRequested(real h)

    implicitWidth: parent?.width ?? 0
    implicitHeight: root.open ? root.bodyHeight : 0
    height: root.implicitHeight
    visible: root.height > 0
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
            onRunningChanged: if (!running && root.open)
                Qt.callLater(() => root.revealRequested(root.bodyHeight))
        }
    }

    component FormRow: Item {
        id: fr
        property string label: ""
        property string sublabel: ""
        default property alias content: slot.data

        implicitWidth: parent?.width ?? 0
        implicitHeight: fr.sublabel !== "" ? 56 : 48

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: slot.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: fr.label
                elide: Text.ElideRight
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.on_surface
            }

            Text {
                width: parent.width
                visible: fr.sublabel !== ""
                text: fr.sublabel
                elide: Text.ElideRight
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.outline
            }
        }

        Row {
            id: slot
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
        }

        Rectangle {
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

    Loader {
        id: loader
        width: root.width
        active: root.open || root.height > 0
        sourceComponent: body
    }

    Component {
        id: body

        Column {
            id: col

            property bool pickerOpen: false

            Item {
                visible: root.topRule
                width: col.width
                height: visible ? 1 : 0

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }

            FormRow {
                label: Localization.t("powerMenuPage.label")

                TextInputField {
                    implicitWidth: 220
                    text: root.draft.label ?? ""
                    onEdited: v => root.edited("label", v)
                }
            }

            FormRow {
                label: Localization.t("powerMenuPage.command")
                sublabel: Localization.t("powerMenuPage.command_sub")

                TextInputField {
                    implicitWidth: 320
                    text: root.draft.command ?? ""
                    onEdited: v => root.edited("command", v)
                }
            }

            FormRow {
                label: Localization.t("powerMenuPage.key")
                sublabel: Localization.t("powerMenuPage.key_sub")

                TextInputField {
                    implicitWidth: 56
                    text: root.draft.key ?? ""
                    validator: RegularExpressionValidator {
                        regularExpression: /[A-Za-z]?/
                    }
                    onEdited: v => root.edited("key", v)
                }
            }

            FormRow {
                label: Localization.t("powerMenuPage.hold")
                sublabel: Localization.t("powerMenuPage.hold_sub")

                Md3Switch {
                    checked: root.draft.hold === true
                    onToggled: v => root.edited("hold", v)
                }
            }

            FormRow {
                label: Localization.t("powerMenuPage.icon")
                sublabel: Localization.t("powerMenuPage.icon_sub")

                ActionButton {
                    icon: root.draft.icon ?? ""
                    label: root.draft.icon ?? ""
                    onClicked: col.pickerOpen = !col.pickerOpen
                }
            }

            Item {
                id: pickerHolder
                width: col.width
                height: col.pickerOpen ? picker.implicitHeight + 20 : 0
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                IconPicker {
                    id: picker
                    x: 18
                    y: 8
                    width: pickerHolder.width - 36
                    height: picker.implicitHeight
                    active: col.pickerOpen || pickerHolder.height > 0
                    currentIcon: root.draft.icon ?? ""
                    onPicked: n => root.edited("icon", n)
                }
            }

            Item {
                width: col.width
                height: 56

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ActionButton {
                        label: Localization.t("lockSurface.cancel")
                        onClicked: root.cancelled()
                    }

                    ActionButton {
                        icon: "check"
                        label: Localization.t("powerMenuPage.save")
                        enabled: root.valid
                        onClicked: root.saved()
                    }
                }
            }
        }
    }
}
