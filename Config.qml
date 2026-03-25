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

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool spinningCover: true
            property bool showSeconds: false
            property int carouselSpeed: 30
            property bool transparentBar: false
            property string fontFamily: "Inter"
        }
    }
}
