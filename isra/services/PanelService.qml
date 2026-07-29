pragma Singleton
import Quickshell

Singleton {
    id: root

    property var current: null
    property var currentScreen: null

    function opened(panel: var, screen: var): void {
        if (root.current === panel)
            return;
        const prev = root.current;
        root.current = panel;
        root.currentScreen = screen ?? null;
        if (prev)
            prev.close();
    }

    function closed(panel: var): void {
        if (root.current === panel) {
            root.current = null;
            root.currentScreen = null;
        }
    }

    function closeAll(): void {
        const prev = root.current;
        root.current = null;
        if (prev)
            prev.close();
    }
}
