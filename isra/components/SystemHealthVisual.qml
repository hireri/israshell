pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.style
import qs.icons
import qs.services
import qs.windows

Item {
    id: root

    property bool interactive: true
    property bool showAreas: true
    property bool showDetail: true
    property bool tinted: false
    property var areaList: ["packages", "storage", "system"]

    readonly property int pad: 14
    readonly property int rowH: 22
    readonly property int tile: 40
    readonly property var areas: root.areaList.filter(a => root.members[a] !== undefined)
    readonly property var members: ({ packages: ["packages"], storage: ["storage"], system: ["hardware", "services", "system"] })
    readonly property bool known: HealthService.enabled && HealthService.probed
    readonly property string phase: !HealthService.enabled ? "off" : !root.known ? "checking" : Object.keys(HealthService.groupWorst).length === 0 ? "none" : HealthService.worst
    readonly property int fit: root.showAreas ? Math.max(0, Math.min(root.areas.length, Math.floor((root.height - root.pad * 2 - root.tile - 12 + 4) / (root.rowH + 4)))) : 0
    readonly property bool showSub: root.showDetail && root.width >= 200
    readonly property var lead: HealthService.highlights.length > 0 ? HealthService.highlights[0] : null

    readonly property color _container: root.phase === "bad" ? Colors.md3.error_container : root.phase === "warn" ? Colors.md3.tertiary_container : Colors.md3.secondary_container
    readonly property color _onContainer: root.phase === "bad" ? Colors.md3.on_error_container : root.phase === "warn" ? Colors.md3.on_tertiary_container : Colors.md3.on_secondary_container

    readonly property bool tintOn: root.tinted && (root.phase === "warn" || root.phase === "bad")
    readonly property color fg: root.tintOn ? root._onContainer : Colors.md3.on_surface
    readonly property color fgDim: root.tintOn ? Qt.alpha(root._onContainer, 0.75) : Colors.md3.outline

    function dot(group: string): color {
        const present = root.members[group].filter(g => HealthService.groupWorst[g] !== undefined);
        const w = present.length === 0 ? "" : HealthService._worstOf(present.map(g => HealthService.groupWorst[g]));
        return w === "bad" ? Colors.md3.error : w === "warn" ? Colors.md3.tertiary : w === "" ? Qt.alpha(Colors.md3.outline, 0.5) : Colors.md3.primary;
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: root.tintOn ? root._container : (Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !Config.desktopWidgetsBlurActive
            shadowBlur: 0.5
            shadowColor: Qt.alpha("black", 0.2)
            shadowVerticalOffset: 4
        }
    }

    Item {
        anchors {
            fill: parent
            margins: root.pad
        }

        Rectangle {
            id: badge
            width: root.tile
            height: root.tile
            radius: 12
            color: root.tintOn ? Qt.alpha(root._onContainer, 0.14) : root._container

            MaterialIcon {
                anchors.centerIn: parent
                name: root.lead ? root.lead.icon : "overview"
                iconSize: 22
                color: root._onContainer
                transitionType: "none"
            }
        }

        Column {
            anchors {
                left: badge.right
                leftMargin: 12
                right: parent.right
                verticalCenter: badge.verticalCenter
            }
            spacing: 1

            Text {
                width: parent.width
                text: Localization.t("systemApp.hero_" + root.phase)
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.weight: Font.Medium
                color: root.fg
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                width: parent.width
                text: root.lead ? root.lead.text : Localization.t("systemApp.title")
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: root.fgDim
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
                top: badge.bottom
                topMargin: 12
            }
            spacing: 4
            visible: root.known

            Repeater {
                model: root.areas.slice(0, root.fit)

                Item {
                    id: area
                    required property string modelData
                    width: parent.width
                    height: root.rowH

                    Rectangle {
                        id: dotItem
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: root.dot(area.modelData)
                    }

                    Text {
                        id: nameText
                        anchors.left: dotItem.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.showSub ? Math.min(implicitWidth, parent.width * 0.4) : parent.width - 18
                        text: Localization.t("systemApp." + area.modelData)
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: root.fg
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Text {
                        visible: root.showSub
                        anchors.left: nameText.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: SystemPages.sublabel(area.modelData)
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: root.fgDim
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "system", "open", root.lead ? root.lead.page : "overview"])
    }
}
