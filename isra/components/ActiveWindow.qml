import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Rectangle {
    id: root
    readonly property int activeWidth: 220
    readonly property int horizontalPadding: 10

    readonly property var activeWindow: Hyprland.activeToplevel

    color: {
        if (Config.bar.transparentPills) {
            Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container
        } else {
            Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
        }
    }
    radius: 16
    height: 32

    width: activeWidth
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

    readonly property bool showFallback: !activeWindow
    readonly property string fallbackAppId: "Desktop"
    readonly property string fallbackTitle: "Empty workspace"

    readonly property string kaomoji: " > ⩊ < "

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

        const newSource = getIconSource(rawAppId);

        displayedAppId = rawAppId;
        displayedTitle = rawTitle;

        const appIdText = w ? rawAppId : fallbackAppId;
        const titleText = w ? rawTitle : fallbackTitle;

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

    Connections {
        target: activeWindow || null
        ignoreUnknownSignals: true

        function onTitleChanged() {
            displayedTitle = activeWindow.title ?? "";
            if (layerA)
                textTitleA = displayedTitle;
            else
                textTitleB = displayedTitle;
        }

        function onWaylandChanged() {
            const rawAppId = getAppId(activeWindow);
            const newSource = getIconSource(rawAppId);

            displayedAppId = rawAppId;

            if (layerA) {
                textAppIdA = rawAppId;
                iconSourceA = newSource;
            } else {
                textAppIdB = rawAppId;
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
        textAppIdA = w ? rawAppId : fallbackAppId;
        textTitleA = w ? rawTitle : fallbackTitle;
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
            }

            Image {
                id: iconB
                anchors.fill: parent
                source: iconSourceB
                opacity: 0
                sourceSize: Qt.size(22, 22)
                fillMode: Image.PreserveAspectCrop
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
