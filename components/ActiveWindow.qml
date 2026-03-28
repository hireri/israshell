import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Item {
    id: root
    readonly property int maxTextWidth: 450
    readonly property var activeWindow: Hyprland.toplevels.values.find(t => t.activated)

    readonly property int maxTitleChars: 60
    readonly property int maxAppIdChars: 40

    implicitWidth: leftContent.implicitWidth + 20
    height: 32

    property bool layerA: true

    property string iconSourceA: ""
    property string iconSourceB: ""
    property string textAppIdA: ""
    property string textTitleA: ""
    property string textAppIdB: ""
    property string textTitleB: ""
    property string displayedAppId: ""
    property string displayedTitle: ""

    readonly property bool showFallback: !activeWindow

    readonly property string kaomoji: " > ⩊ < "
    readonly property int kaomojiFallbackWidth: kaomeasure.implicitWidth + 12

    Text {
        id: kaomeasure
        visible: false
        text: root.kaomoji
        font.pixelSize: 10
        font.family: Config.fontFamily
    }

    function truncateText(str, maxLength) {
        if (!str)
            return "";
        if (str.length > maxLength)
            return str.substring(0, maxLength).trim() + "...";
        return str;
    }

    function getAppId(w) {
        if (!w)
            return "";
        return w.wayland?.appId || w.lastIpcObject?.class || w.lastIpcObject?.initialClass || "";
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
        const rawAppId = getAppId(w);
        const rawTitle = w ? (w.title ?? "") : "";

        const newAppId = truncateText(rawAppId, maxAppIdChars);
        const newTitle = truncateText(rawTitle, maxTitleChars);
        const newSource = getIconSource(rawAppId);

        displayedAppId = rawAppId;
        displayedTitle = rawTitle;

        if (layerA) {
            iconSourceB = newSource;
            textAppIdB = newAppId;
            textTitleB = newTitle;
        } else {
            iconSourceA = newSource;
            textAppIdA = newAppId;
            textTitleA = newTitle;
        }

        layerA = !layerA;
        crossfade.restart();
    }

    onActiveWindowChanged: updateWindowInfo()

    Connections {
        target: activeWindow || null
        ignoreUnknownSignals: true

        function onTitleChanged() {
            const truncatedTitle = truncateText(activeWindow.title, maxTitleChars);
            displayedTitle = activeWindow.title ?? "";
            if (layerA)
                textTitleA = truncatedTitle;
            else
                textTitleB = truncatedTitle;
        }

        function onWaylandChanged() {
            const rawAppId = getAppId(activeWindow);
            const newAppId = truncateText(rawAppId, maxAppIdChars);
            const newSource = getIconSource(rawAppId);

            displayedAppId = rawAppId;

            if (layerA) {
                textAppIdA = newAppId;
                iconSourceA = newSource;
            } else {
                textAppIdB = newAppId;
                iconSourceB = newSource;
            }
        }
    }

    Component.onCompleted: {
        const w = activeWindow;
        const rawAppId = getAppId(w);
        const rawTitle = w?.title ?? "";

        displayedAppId = rawAppId;
        displayedTitle = rawTitle;
        iconSourceA = getIconSource(rawAppId);
        textAppIdA = truncateText(rawAppId, maxAppIdChars);
        textTitleA = truncateText(rawTitle, maxTitleChars);
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
        id: leftContent
        anchors.centerIn: parent
        spacing: 8

        ClippingRectangle {
            id: iconContainer
            implicitWidth: showFallback ? kaomojiFallbackWidth : 32
            implicitHeight: 32
            anchors.verticalCenter: parent.verticalCenter
            radius: 10
            color: "transparent"

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

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
                sourceSize: Qt.size(32, 32)
                fillMode: Image.PreserveAspectCrop
            }

            Image {
                id: iconB
                anchors.fill: parent
                source: iconSourceB
                opacity: 0
                sourceSize: Qt.size(32, 32)
                fillMode: Image.PreserveAspectCrop
            }
        }

        Item {
            id: textContainer
            anchors.verticalCenter: parent.verticalCenter
            height: textColA.implicitHeight
            clip: true

            width: {
                const activeW = layerA ? Math.max(appIdTextA.implicitWidth, titleTextA.implicitWidth) : Math.max(appIdTextB.implicitWidth, titleTextB.implicitWidth);
                return Math.min(activeW, maxTextWidth);
            }

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

            Column {
                id: textColA
                width: textContainer.width
                opacity: 1

                Text {
                    id: appIdTextA
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdA
                }
                Text {
                    id: titleTextA
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
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdB
                }
                Text {
                    id: titleTextB
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    text: textTitleB
                }
            }
        }
    }
}
