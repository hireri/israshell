import QtQuick
import Quickshell
import qs.services
import qs.style

Tooltip {
    id: root

    property var panelWindow: QsWindow.window

    autoHover: false

    suppressed: PanelService.current !== null

    melt: root.panelWindow?.meltActive ?? false
    revealFromBottom: Config.bar.position === 1

    property QtObject _reporter: MeltReporter {
        win: root.panelWindow
        key: "tooltip" + String(root)
        rect: Qt.rect(root.tipX, root.tipY + root.revealY, root.tipWidth, root.tipHeight * root.meltP)
        active: root.melt && root.meltP > 0.001
    }

    tipY: {
        const barHeight = root.panelWindow?.barHeight ?? 0;
        const g = root.melt ? 0 : root.gap;
        return Config.bar.position === 1 ? (root.host?.height ?? 0) - barHeight - root.tipHeight - g : barHeight + g;
    }
}
