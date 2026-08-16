pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    readonly property string assetRoot: Quickshell.shellDir + "/assets/weather"

    property var sceneManifest: ({})

    FileView {
        id: manifestFile
        path: root.assetRoot + "/froggie/manifest.json"
        printErrors: false
        onLoaded: {
            try {
                root.sceneManifest = JSON.parse(manifestFile.text());
            } catch (e) {
                console.warn("[WeatherAssets] manifest parse failed:", e);
            }
        }
    }

    function iconName(code, isDay): string {
        const c = parseInt(code);
        const day = isDay !== false;
        switch (c) {
        case 0:
            return day ? "clear_day" : "clear_night";
        case 1:
            return day ? "clear_day" : "mostly_clear_night";
        case 2:
            return day ? "partly_cloudy_day" : "partly_cloudy_night";
        case 3:
            return "cloudy";
        case 45:
        case 48:
            return "haze_fog";
        case 51:
        case 53:
        case 55:
            return "drizzle";
        case 56:
        case 57:
        case 66:
        case 67:
            return "icy";
        case 61:
        case 63:
            return "rain_showers";
        case 65:
        case 82:
            return "heavy_rain";
        case 71:
        case 73:
        case 77:
            return "flurries";
        case 75:
        case 86:
            return "heavy_snow";
        case 80:
        case 81:
            return day ? "scattered_rain_showers_day" : "scattered_rain_showers_night";
        case 85:
            return day ? "scattered_snow_showers_day" : "scattered_snow_showers_night";
        case 95:
            return day ? "thunderstorms_day" : "thunderstorms_night";
        case 96:
        case 99:
            return "strong_thunderstorms";
        default:
            return "not_available";
        }
    }

    function iconPath(code, isDay): string {
        const variant = Colors.md3 && Config.darkMode ? "dark" : "light";
        return root.assetRoot + "/icons/" + variant + "/" + root.iconName(code, isDay) + ".svg";
    }

    function sceneCondition(code, isDay): string {
        const c = parseInt(code);
        const day = isDay !== false;
        switch (c) {
        case 0:
            return day ? "01-sunny" : "05-clear";
        case 1:
            return day ? "02-mostly-sunny" : "06-mostly-clear";
        case 2:
            return day ? "03-partly-cloudy-day" : "07-partly-cloudy-night";
        case 3:
            return "09-cloudy";
        case 45:
        case 48:
            return "26-haze-fog-dust-smoke";
        case 51:
        case 53:
        case 55:
            return "10-drizzle";
        case 56:
        case 57:
        case 66:
        case 67:
            return "19-mixed-rain-hail-rain-sleet";
        case 61:
        case 63:
        case 80:
        case 81:
            return "11-rain";
        case 65:
        case 82:
            return "12-heavy-rain";
        case 71:
        case 73:
        case 77:
            return "13-flurries";
        case 75:
        case 86:
            return "17-heavy-snow-blizzard";
        case 85:
            return "15-snow-showers-snow";
        case 95:
            return "23-scattered-thunderstorms";
        case 96:
        case 99:
            return "24-strong-thunderstorms";
        default:
            return "00-neutral";
        }
    }

    function scenePath(code, isDay, salt): string {
        const condition = root.sceneCondition(code, isDay);
        const list = root.sceneManifest[condition] ?? [];
        if (list.length === 0)
            return "";
        const idx = Math.abs(Math.floor(salt ?? 0)) % list.length;
        return root.assetRoot + "/froggie/" + condition + "/" + list[idx];
    }

    function overlayName(code, isDay): string {
        const c = parseInt(code);
        const day = isDay !== false;
        switch (c) {
        case 0:
        case 1:
            return day ? "sunny" : "";
        case 2:
            return day ? "mostly_sunny" : "";
        case 3:
            return "mostly_cloudy";
        case 45:
        case 48:
            return "haze_smoke";
        case 51:
        case 53:
        case 55:
            return "drizzle";
        case 56:
        case 57:
        case 66:
        case 67:
            return "mixed_rain_hail";
        case 61:
        case 63:
            return "showers_rain";
        case 65:
        case 82:
            return "showers_rain";
        case 71:
        case 73:
        case 77:
            return "flurries";
        case 75:
            return "heavy_snow";
        case 86:
            return "blizzard";
        case 80:
        case 81:
            return day ? "scattered_showers" : "scattered_showers_night";
        case 85:
            return day ? "scattered_snow" : "scattered_snow_night";
        case 95:
        case 96:
        case 99:
            return "strong_storms";
        default:
            return "";
        }
    }

    function overlayPath(code, isDay): string {
        const name = root.overlayName(code, isDay);
        if (name === "")
            return "";
        const suffix = name.endsWith("_night") ? name.replace("_night", "_foreground_night") : name + "_foreground";
        return root.assetRoot + "/lottie/" + suffix + ".json";
    }

    readonly property var allOverlayNames: ["blizzard", "blowing_snow", "drizzle", "flurries", "haze_smoke", "heavy_snow", "mixed_rain_hail", "mostly_cloudy", "mostly_sunny", "scattered_showers", "scattered_showers_night", "scattered_snow", "scattered_snow_night", "showers_rain", "showers_snow", "strong_storms", "sunny", "windy_breezy"]

    function overlayPathByName(name): string {
        const suffix = name.endsWith("_night") ? name.replace("_night", "_foreground_night") : name + "_foreground";
        return root.assetRoot + "/lottie/" + suffix + ".json";
    }
}
