import Quickshell
import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

import qs.style
import qs.services

Rectangle {
    id: root
    readonly property int maxActiveWidth: 220
    readonly property int horizontalPadding: 10

    readonly property var activeWindow: CompositorService.activeWindow

    color: {
        if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else {
            Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        }
    }
    radius: 16
    height: 32

    readonly property real naturalContentWidth: horizontalPadding * 2 + iconContainer.width + contentRow.spacing
        + Math.max(appIdTextA.implicitWidth, titleTextA.implicitWidth, appIdTextB.implicitWidth, titleTextB.implicitWidth)

    width: Math.min(maxActiveWidth, naturalContentWidth)
    implicitWidth: width

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    property bool layerA: true

    property string iconSourceA: ""
    property string iconSourceB: ""
    property string textAppIdA: ""
    property string textTitleA: ""
    property string textAppIdB: ""
    property string textTitleB: ""
    property string displayedAppId: ""
    property string displayedTitle: ""

    readonly property bool showFallback: !activeWindow || (!activeWindow.address && !activeWindow.appId)
    readonly property string fallbackAppId: Localization.t("activeWindow.desktop")
    readonly property string fallbackTitle: Localization.t("activeWindow.empty_workspace")

    readonly property string kaomoji: " > ⩊ < "

    function getAppId(w) {
        return w?.appId || "";
    }

    function getIconSource(appId) {
        if (!appId)
            return "";

        if (appId.startsWith("steam_app_")) {
            const steamId = appId.replace("steam_app_", "");
            return "image://icon/steam_icon_" + steamId + "?fallback=steam";
        }

        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.icon) {
            return "image://icon/" + entry.icon + "?fallback=application-x-executable";
        }

        return "image://icon/" + appId + "?fallback=application-x-executable";
    }

    function updateWindowInfo() {
        const w = activeWindow;
        const empty = !w || (!w.address && !w.appId);
        const rawAppId = getAppId(w);
        const rawTitle = w ? (w.title ?? "") : "";

        const newSource = getIconSource(rawAppId);

        displayedAppId = rawAppId;
        displayedTitle = rawTitle;

        const appIdText = empty ? fallbackAppId : rawAppId;
        const titleText = empty ? fallbackTitle : rawTitle;

        if (layerA) {
            iconSourceB = newSource;
            textAppIdB = appIdText;
            textTitleB = titleText;
        } else {
            iconSourceA = newSource;
            textAppIdA = appIdText;
            textTitleA = titleText;
        }

        layerA = !layerA;
        crossfade.restart();
    }

    onActiveWindowChanged: updateWindowInfo()

    Component.onCompleted: {
        const w = activeWindow;
        const empty = !w || (!w.address && !w.appId);
        const rawAppId = getAppId(w);
        const rawTitle = w?.title ?? "";

        displayedAppId = rawAppId;
        displayedTitle = rawTitle;
        iconSourceA = getIconSource(rawAppId);
        textAppIdA = empty ? fallbackAppId : rawAppId;
        textTitleA = empty ? fallbackTitle : rawTitle;
    }

    ParallelAnimation {
        id: crossfade
        NumberAnimation {
            target: iconA
            property: "opacity"
            to: layerA ? 1 : 0
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: iconB
            property: "opacity"
            to: layerA ? 0 : 1
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: textColA
            property: "opacity"
            to: layerA ? 1 : 0
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: textColB
            property: "opacity"
            to: layerA ? 0 : 1
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        ClippingRectangle {
            id: iconContainer
            implicitWidth: 22
            implicitHeight: 22
            anchors.verticalCenter: parent.verticalCenter
            radius: showFallback ? 11 : 6
            color: Colors.md3.surface_container_highest

            Rectangle {
                anchors.fill: parent
                color: Colors.md3.secondary_container
                visible: showFallback

                Text {
                    anchors.centerIn: parent
                    text: kaomoji
                    color: Colors.md3.on_secondary_container
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    font.weight: Font.Medium
                }
            }

            Image {
                id: iconA
                anchors.fill: parent
                source: iconSourceA
                opacity: 1
                sourceSize: Qt.size(22, 22)
                fillMode: Image.PreserveAspectCrop
                visible: !Config.tintIcons
            }

            Image {
                id: iconB
                anchors.fill: parent
                source: iconSourceB
                opacity: 0
                sourceSize: Qt.size(22, 22)
                fillMode: Image.PreserveAspectCrop
                visible: !Config.tintIcons
            }

            Loader {
                active: Config.tintIcons
                anchors.fill: iconA
                opacity: iconA.opacity
                sourceComponent: Colorize {
                    source: iconA
                    hue: Qt.color(Colors.md3.on_surface).hslHue
                    saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                    lightness: 0.0
                }
            }

            Loader {
                active: Config.tintIcons
                anchors.fill: iconB
                opacity: iconB.opacity
                sourceComponent: Colorize {
                    source: iconB
                    hue: Qt.color(Colors.md3.on_surface).hslHue
                    saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                    lightness: 0.0
                }
            }
        }

        Item {
            id: textContainer
            anchors.verticalCenter: parent.verticalCenter
            height: Math.max(textColA.implicitHeight, textColB.implicitHeight)
            clip: true

            width: Math.max(0, root.width - iconContainer.width - contentRow.spacing - (root.horizontalPadding * 2))

            Column {
                id: textColA
                width: textContainer.width
                opacity: 1

                Text {
                    id: appIdTextA
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdA
                }
                Text {
                    id: titleTextA
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    text: textTitleA
                }
            }

            Column {
                id: textColB
                width: textContainer.width
                opacity: 0

                Text {
                    id: appIdTextB
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdB
                }
                Text {
                    id: titleTextB
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    text: textTitleB
                }
            }
        }
    }
}
