pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.components

Item {
    id: root

    property string iconSource: ""
    property color iconBg: Colors.md3.primary_container
    property string label: ""
    property string sublabel: ""
    property string tooltip: ""

    property bool isLast: false

    property bool compact: false
    property bool stack: false

    property string settingKey: ""
    property string settingKeywords: ""
    property string settingType: "custom"
    property string settingsPath: ""
    property var settingsValue: null
    property var settingsMeta

    property string applySignal: ""

    function applyValue(value) {
        if (root.applySignal !== "") {
            root[root.applySignal](value);
            return;
        }
        console.warn("[SettingRow] '" + root.label + "' (" + root.settingType + ") does not support applyValue");
    }

    Component.onCompleted: SettingsRegistry.register(root)
    Component.onDestruction: SettingsRegistry.unregister(root)

    readonly property real sideMargin: root.compact ? 14 : 18
    readonly property real contentWidth: root.width - root.sideMargin * 2

    default property alias content: trailingSlot.data
    property Item leading: null
    onLeadingChanged: if (root.leading) root.leading.parent = leadingSlot

    implicitHeight: Math.max(root.compact ? 44 : 56, contentCol.implicitHeight + (root.compact ? 14 : 20))
    implicitWidth: parent?.width ?? 0

    property real topRadius: 18
    property real bottomRadius: 18

    Rectangle {
        anchors.fill: parent
        color: Config.dim(Colors.md3.surface_container)
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius

        Behavior on topLeftRadius {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on bottomLeftRadius {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.sideMargin
            rightMargin: root.sideMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: root.stack ? 6 : 0

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            spacing: root.compact ? 10 : 14

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: root.iconBg
                visible: root.iconSource !== ""
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    source: root.iconSource
                    width: 18
                    height: 18
                    smooth: true
                    asynchronous: true
                    cache: true
                    sourceSize: Qt.size(36, 36)
                }
            }

            Item {
                id: leadingSlot
                visible: root.leading !== null
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.leading?.width ?? 0
                implicitHeight: root.leading?.height ?? 0
            }

            ColumnLayout {
                id: labelCol
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                visible: root.label !== ""

                Text {
                    id: labelText
                    text: root.label
                    font.family: Config.fontFamily
                    font.pixelSize: root.compact ? 12 : 13
                    color: Colors.md3.on_surface
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    id: sublabelText
                    text: root.sublabel
                    font.family: Config.fontFamily
                    font.pixelSize: root.compact ? 10 : 11
                    color: Colors.md3.outline
                    visible: root.sublabel !== ""
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    Tooltip {
        anchorItem: root.label !== "" ? labelCol : root
        text: root.tooltip !== "" ? root.tooltip : (labelText.truncated || sublabelText.truncated ? root.label + (root.sublabel !== "" ? "\n" + root.sublabel : "") : "")
    }

    Row {
        id: trailingSlot
        parent: root.stack ? contentCol : contentRow
        Layout.alignment: Qt.AlignVCenter
        spacing: 8
    }
}
