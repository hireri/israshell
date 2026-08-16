pragma Singleton
import Quickshell
import qs.style
import qs.services

Singleton {
    id: root

    property bool active: false
    property var _snapshot: null

    property string selectedId: ""
    property var selectedScreen: null

    signal nudgeRequested(real dx, real dy)
    signal deleteRequested

    property int _openSettingsPanels: 0
    readonly property bool settingsOpen: root._openSettingsPanels > 0

    function settingsPanelOpened(): void {
        root._openSettingsPanels++;
    }

    function settingsPanelClosed(): void {
        root._openSettingsPanels = Math.max(0, root._openSettingsPanels - 1);
    }

    function select(id: string, screen: var): void {
        root.selectedId = id ?? "";
        root.selectedScreen = root.selectedId === "" ? null : (screen ?? null);
    }

    function isSelected(id: string, screen: var): bool {
        return root.active && id !== "" && root.selectedId === id && root.selectedScreen === screen;
    }

    function clearSelection(): void {
        root.selectedId = "";
        root.selectedScreen = null;
    }

    onActiveChanged: active ? PanelService.modeOpened(root) : PanelService.modeClosed(root)

    function close(): void {
        root.disable();
    }

    function enable(): void {
        if (!root.active) {
            root._snapshot = {
                desktopWidgets: (Config.desktopWidgets ?? []).map(w => Object.assign({}, w, {
                    data: Object.assign({}, w.data),
                    positions: Object.assign({}, w.positions)
                }))
            };
        }
        root.active = true;
    }

    function disable(): void {
        root.clearSelection();
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
        root.clearSelection();
        Config.update({ desktopWidgets: root._snapshot.desktopWidgets });
    }
}
