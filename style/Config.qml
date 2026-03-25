//@ pragma UseQApplication
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property alias spinningCover: adapter.spinningCover
    property alias showSeconds: adapter.showSeconds
    property alias carouselSpeed: adapter.carouselSpeed
    property alias transparentBar: adapter.transparentBar
    property alias fontFamily: adapter.fontFamily
    property alias trayBlacklist: adapter.trayBlacklist

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            readonly property bool spinningCover: true
            readonly property bool showSeconds: false
            readonly property int carouselSpeed: 30
            readonly property bool transparentBar: false
            readonly property string fontFamily: "Inter"
            readonly property var trayBlacklist: ["spotify", "Spotify"]
        }
    }
}
