import QtQuick
import Quickshell
import qs.services
import qs.style

Tooltip {
    id: root

    property var panelWindow: QsWindow.window

    autoHover: false

    suppressed: PanelService.current !== null

    tipY: {
        const barHeight = root.panelWindow?.barHeight ?? 0;
        return Config.bar.position === 1 ? (root.host?.height ?? 0) - barHeight - root.tipHeight - root.gap : barHeight + root.gap;
    }
}
