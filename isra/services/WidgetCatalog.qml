pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.components

Singleton {
    id: root

    Component { id: weyesPreview; WeyesEyes { tracking: false } }
    Component { id: musicPreview; MusicVisual { interactive: false } }
    Component { id: photoPreview; PhotoVisual { shape: "circle" } }
    Component { id: statRingPreview; StatRingVisual { metric: "cpu" } }
    Component { id: weatherPreview; WeatherGlanceVisual {} }
    Component { id: weatherCardPreview; WeatherCardVisual {} }
    Component { id: weatherScenePreview; WeatherSceneVisual {} }
    Component { id: pomodoroPreview; PomodoroVisual {} }
    Component { id: githubHeatmapPreview; GithubHeatmapVisual {} }
    Component { id: sunMoonPreview; SunMoonVisual {} }
    Component { id: fetchCardPreview; FetchCardVisual {} }

    readonly property var types: [
        {
            type: "photo",
            label: Localization.t("widgetDrawer.photo"),
            icon: "image",
            preview: photoPreview,
            stackable: true
        },
        {
            type: "music",
            label: Localization.t("widgetDrawer.music"),
            icon: "music-note",
            preview: musicPreview,
            stackable: false
        },
        {
            type: "weyes",
            label: Localization.t("widgetDrawer.weyes"),
            icon: "visibility",
            preview: weyesPreview,
            stackable: false
        },
        {
            type: "statring",
            label: Localization.t("widgetDrawer.statring"),
            icon: "memory",
            preview: statRingPreview,
            stackable: true
        },
        {
            type: "weather",
            label: Localization.t("widgetDrawer.weather"),
            icon: "partly-cloudy-day",
            preview: weatherPreview,
            stackable: false
        },
        {
            type: "weathercard",
            label: Localization.t("widgetDrawer.weather_card"),
            icon: "cloudy",
            preview: weatherCardPreview,
            stackable: false
        },
        {
            type: "weatherscene",
            label: Localization.t("widgetDrawer.weather_scene"),
            icon: "wb-sunny",
            preview: weatherScenePreview,
            stackable: false
        },
        {
            type: "pomodoro",
            label: Localization.t("widgetDrawer.pomodoro"),
            icon: "analog-clock",
            preview: pomodoroPreview,
            stackable: false
        },
        {
            type: "githubheatmap",
            label: Localization.t("widgetDrawer.github_heatmap"),
            icon: "calendar-month",
            preview: githubHeatmapPreview,
            stackable: true
        },
        {
            type: "sunmoon",
            label: Localization.t("widgetDrawer.sunmoon"),
            icon: "moon-stars",
            preview: sunMoonPreview,
            stackable: true
        },
        {
            type: "fetchcard",
            label: Localization.t("widgetDrawer.fetchcard"),
            icon: "terminal",
            preview: fetchCardPreview,
            stackable: false
        }
    ]

    function descriptor(type) {
        return root.types.find(t => t.type === type) ?? null;
    }

    function previewSize(type) {
        const d = DesktopWidgetService.defaultsFor(type);
        if (!d)
            return Qt.size(100, 100);
        if (d.span)
            return Qt.size(WidgetGrid.spanWidth(null, d.span.w), WidgetGrid.spanHeight(null, d.span.h));
        return Qt.size(d.width ?? 100, d.height ?? 100);
    }

    function available(type) {
        return root.descriptor(type) !== null && DesktopWidgetService.isAvailable(type);
    }

    function unavailableReason(type) {
        if (root.available(type))
            return "";
        return Localization.t("widgetDrawer.requires_cursor_position").replace("%1", CompositorService.backendName);
    }

    function count(type) {
        return root.descriptor(type) ? DesktopWidgetService.countOf(type) : 0;
    }

    function present(type) {
        return root.count(type) > 0;
    }

    function canAdd(type) {
        return root.descriptor(type) !== null && DesktopWidgetService.canAddInstance(type);
    }

    function add(type, screen) {
        if (!root.canAdd(type))
            return null;
        return DesktopWidgetService.addWidget(type, screen);
    }

    function removeType(type) {
        const entry = DesktopWidgetService.firstOf(type);
        if (entry)
            DesktopWidgetService.removeEntry(entry.id);
    }

    function toggles(type) {
        const d = root.descriptor(type);
        return !!d && !d.stackable;
    }
}
