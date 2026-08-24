pragma Singleton
import Quickshell

Singleton {
    id: root

    property var current: null
    property var currentScreen: null
    property var currentMode: null

    function opened(panel: var, screen: var): void {
        if (root.current === panel) {
            root.currentScreen = screen ?? null;
            return;
        }
        const prev = root.current;
        root.current = panel;
        root.currentScreen = screen ?? null;
        if (prev)
            prev.close();
        if (root.currentMode && panel?.coexistsWithMode !== true)
            root._closeMode();
    }

    function closed(panel: var): void {
        if (root.current === panel) {
            root.current = null;
            root.currentScreen = null;
        }
    }

    function register(panel: var, controllerRegistry: var, screenRegistry: var, screenName: string): void {
        if (screenRegistry && screenName)
            screenRegistry[screenName] = panel;
        if (controllerRegistry && panel.panelType)
            controllerRegistry[panel.panelType] = panel;
    }

    function modeOpened(mode: var): void {
        if (root.currentMode === mode)
            return;
        const prev = root.currentMode;
        root.currentMode = mode;
        if (prev)
            prev.close();
    }

    function modeClosed(mode: var): void {
        if (root.currentMode === mode)
            root.currentMode = null;
    }

    function _closeMode(): void {
        const prev = root.currentMode;
        root.currentMode = null;
        if (prev)
            prev.close();
    }

    function closeAll(instant): void {
        const prev = root.current;
        root.current = null;
        root.currentScreen = null;
        root._closeMode();
        if (!prev)
            return;
        if (instant && prev.closeInstantly)
            prev.closeInstantly();
        else
            prev.close();
    }
}
