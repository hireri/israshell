pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.style

Singleton {
    id: root

    property bool active: false

    function toggle() {
        root.active = !root.active;
    }

    onActiveChanged: {
        if (Config.bedtime.grayscaleTheme ?? false)
            WallpaperService.applyTheme()
    }

    property var _watchedConfig: Config.bedtime
    on_WatchedConfigChanged: {
        if (root.active)
            WallpaperService.applyTheme();
    }
}
