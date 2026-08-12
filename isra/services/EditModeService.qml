pragma Singleton
import Quickshell
import qs.style
import qs.services

Singleton {
    id: root

    property bool active: false
    property var _snapshot: null

    function enable(): void {
        if (!root.active) {
            const clockFields = {};
            for (const field of ClockSizing.scaledFields())
                clockFields[field] = Config.clock[field];
            root._snapshot = {
                clockPositions: Object.assign({}, Config.clockPositions ?? {}),
                clockManualPos: Config.clock.manualPos ?? false,
                clockFields: clockFields,
                weyesPositions: Object.assign({}, Config.weyesPositions ?? {}),
                weyes: Object.assign({}, Config.weyes ?? {})
            };
        }
        root.active = true;
    }

    function disable(): void {
        root.active = false;
    }

    function toggle(): void {
        if (root.active)
            root.disable();
        else
            root.enable();
    }

    function undoChanges(): void {
        if (!root._snapshot)
            return;
        Config.update({ clock: Object.assign({}, Config.clock, { manualPos: false }) });
        Config.update({
            clockPositions: root._snapshot.clockPositions,
            weyesPositions: root._snapshot.weyesPositions,
            weyes: root._snapshot.weyes,
            clock: Object.assign({}, Config.clock, root._snapshot.clockFields)
        });
        if (root._snapshot.clockManualPos) {
            Config.update({ clock: Object.assign({}, Config.clock, { manualPos: true }) });
        }
    }
}
