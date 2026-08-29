import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.lyrics")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 4, h: 2 })
    maxSpan: ({ w: 12, h: 8 })
    frameCornerRadius: 22

    settingsPanel: Component {
        LyricsSettings {
            entryId: shell.entryId
        }
    }

    LyricsVisual {
        anchors.fill: parent

        showCard: shell.entryData.showCard ?? true
        showTrackInfo: shell.entryData.showTrackInfo ?? true
        artSize: shell.entryData.artSize ?? 36
        align: shell.entryData.align || "left"
        idleBlur: shell.entryData.idleBlur ?? 0

        fontFamily: shell.entryData.fontFamily || "Google Sans Flex"
        idleWeight: shell.entryData.idleWeight ?? 380
        activeWeight: shell.entryData.activeWeight ?? 620
        activeGrad: shell.entryData.activeGrad ?? 70
        fontWidth: shell.entryData.fontWidth ?? 100
        fontRoundness: shell.entryData.fontRoundness ?? 0
        lyricSize: shell.entryData.lyricSize ?? 20

        wordMode: shell.entryData.wordMode ?? true
        lineDuration: shell.entryData.lineDuration ?? 620
        wordDuration: shell.entryData.wordDuration ?? 260
        leadIn: shell.entryData.leadIn ?? 120
        activeScale: shell.entryData.activeScale ?? 1.04
    }
}
