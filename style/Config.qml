//@ pragma UseQApplication
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property alias spinningCover: adapter.spinningCover
    property alias showSeconds: adapter.showSeconds
    property alias hourFormat: adapter.hourFormat
    property alias carouselSpeed: adapter.carouselSpeed
    property alias transparentBar: adapter.transparentBar
    property alias fontFamily: adapter.fontFamily
    property alias trayBlacklist: adapter.trayBlacklist
    property alias tintTrayIcons: adapter.tintTrayIcons
    property alias nightLightTemp: adapter.nightLightTemp
    property alias dayLightTemp: adapter.dayLightTemp
    property alias floatingBar: adapter.floatingBar
    property alias huggingBar: adapter.huggingBar
    property alias screenCorners: adapter.screenCorners
    property alias dateFormat: adapter.dateFormat
    property alias osdPosition: adapter.osdPosition

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool spinningCover: true
            property bool showSeconds: false
            property int hourFormat: 0
            property int carouselSpeed: 30
            property bool transparentBar: false
            property string fontFamily: "Inter"
            property var trayBlacklist: ["spotify", "Spotify"]
            property bool tintTrayIcons: false
            property int nightLightTemp: 4000
            property int dayLightTemp: 6500
            property bool floatingBar: true
            property bool huggingBar: false
            property bool screenCorners: true
            property int dateFormat: 0
            property int osdPosition: 0
        }
    }
}
