import QtQuick
import qs.services
import qs.style

Tooltip {
    id: root

    property var panelWindow: null

    suppressed: PanelService.current !== null

    tipY: {
        const barHeight = root.panelWindow?.barHeight ?? 0;
        return Config.bar.position === 1 ? (root.host?.height ?? 0) - barHeight - root.tipHeight - root.gap : barHeight + root.gap;
    }
}
