import QtQuick
import qs.style

Rectangle {
    id: root

    property string title: ""
    property string summary: ""
    property string kind: "other"
    property bool unread: false
    property real date: 0
    property bool featured: false

    signal clicked

    readonly property string badgeIcon: root.kind === "manual" ? "error" : root.kind === "security" ? "shield-lock" : "menu-book"
    readonly property string badgeShape: root.kind === "manual" ? "burst" : root.kind === "security" ? "softBurst" : "cookie6"
    readonly property string kindLabel: root.kind === "other" ? "" : Localization.t("systemApp.news_kind_" + root.kind)

    readonly property bool severe: root.kind !== "other" && root.unread
    readonly property color bg: root.severe ? (root.kind === "manual" ? Colors.md3.error_container : Colors.md3.tertiary_container) : root.featured ? Colors.md3.secondary_container : root.unread ? Colors.md3.primary_container : Config.dim(area.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container)
    readonly property color ink: root.severe ? (root.kind === "manual" ? Colors.md3.on_error_container : Colors.md3.on_tertiary_container) : root.featured ? Colors.md3.on_secondary_container : root.unread ? Colors.md3.on_primary_container : Colors.md3.on_surface
    readonly property color accent: root.kind === "manual" ? Colors.md3.error : root.kind === "security" ? Colors.md3.tertiary : root.featured ? Colors.md3.secondary : Colors.md3.primary
    readonly property color accentInk: root.kind === "manual" ? Colors.md3.on_error : root.kind === "security" ? Colors.md3.on_tertiary : root.featured ? Colors.md3.on_secondary : Colors.md3.on_primary

    radius: 22
    color: root.bg
    scale: area.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.ink
        opacity: area.containsMouse && (root.severe || root.featured || root.unread) ? 0.06 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            ShapeIcon {
                id: badge
                size: root.featured ? 42 : 36
                shape: root.badgeShape
                icon: root.badgeIcon
                immediate: true
                fill: root.unread || root.featured ? root.accent : root.kind === "manual" ? Colors.md3.error_container : root.kind === "security" ? Colors.md3.tertiary_container : Config.dim(Colors.md3.surface_container_highest)
                ink: root.unread || root.featured ? root.accentInk : root.kind === "manual" ? Colors.md3.on_error_container : root.kind === "security" ? Colors.md3.on_tertiary_container : Colors.md3.on_surface_variant
            }

            Text {
                width: parent.width - badge.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Config.fontFamily
                font.pixelSize: root.featured ? 15 : 13
                font.weight: root.unread || root.featured ? Font.Medium : Font.Normal
                color: root.ink
            }
        }

        Text {
            width: parent.width
            visible: root.summary !== ""
            text: root.summary
            wrapMode: Text.WordWrap
            maximumLineCount: root.featured ? 3 : 2
            elide: Text.ElideRight
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Qt.alpha(root.ink, 0.75)
        }
    }

    Text {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 16
            bottomMargin: 12
        }
        visible: root.date > 0
        text: Qt.formatDate(new Date(root.date), "d MMM yyyy") + (root.kindLabel !== "" ? "  ·  " + root.kindLabel : "")
        font.family: Config.fontFamily
        font.pixelSize: 10
        color: Qt.alpha(root.ink, 0.65)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
