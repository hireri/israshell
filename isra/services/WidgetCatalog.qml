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

    readonly property var types: [
        {
            type: "photo",
            label: Localization.t("widgetDrawer.photo"),
            icon: "image",
            preview: photoPreview,
            previewFills: true,
            stackable: true
        },
        {
            type: "music",
            label: Localization.t("widgetDrawer.music"),
            icon: "music-note",
            preview: musicPreview,
            previewFills: true,
            stackable: false
        },
        {
            type: "weyes",
            label: Localization.t("widgetDrawer.weyes"),
            icon: "visibility",
            preview: weyesPreview,
            previewFills: true,
            stackable: false
        },
        {
            type: "statring",
            label: Localization.t("widgetDrawer.statring"),
            icon: "memory",
            preview: statRingPreview,
            previewFills: true,
            stackable: true
        },
        {
            type: "weather",
            label: Localization.t("widgetDrawer.weather"),
            icon: "partly-cloudy-day",
            preview: weatherPreview,
            previewFills: true,
            stackable: false
        },
        {
            type: "weathercard",
            label: Localization.t("widgetDrawer.weather_card"),
            icon: "cloudy",
            preview: weatherCardPreview,
            previewFills: true,
            stackable: false
        },
        {
            type: "weatherscene",
            label: Localization.t("widgetDrawer.weather_scene"),
            icon: "wb-sunny",
            preview: weatherScenePreview,
            previewFills: true,
            stackable: false
        }
    ]

    function descriptor(type) {
        return root.types.find(t => t.type === type) ?? null;
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
