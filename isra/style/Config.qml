pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: configRoot
    property bool showSeconds: false
    property int hourFormat: 0
    property bool stackedSliders: false
    property int carouselSpeed: 30
    property string fontFamily: "Inter"
    property string fontMonospace: "Roboto Mono"
    property bool screenCorners: true
    property bool blurEffects: false
    property int blurRadius: 50
    property real blurOpacity: 0.65
    property var cava: ({
            enabled: false,
            bars: 30,
            position: 1,                // 0 = top, 1 = bottom
            layout: "edges",            // "mono" | "edges" | "center"

            renderType: "curve",        // "curve" | "bars" | "blocks"
            curveType: "smooth",        // "smooth" | "sharp"
            drawFill: true,
            drawStroke: true,

            colorStyle: "loudness",     // "solid" | "loudness" | "gradient-v" | "gradient-h"
            color: "primary",
            colorAlt: "error",

            height: 150,
            opacity: 0.3
        })
    property var workspaces: ({
        compact: false,
        useIcons: true,
        style: 0
    })
    property var bar: ({
            mode: 0,                    // 0 = hugging, 1 = rect,   2 = floating
            position: 0,                // 0 = top,     1 = bottom
            transparency: 0,            // 0 = solid,   1 = opaque, 2 = transparent
            transparentPills: false,

            spinningCover: true,
            playerMode: 0,

            tintTrayIcons: false,
            trayBlacklist: ["spotify", "blueman", "Network"],

            left: ["activeWindow"],
            center: {
                mode: "anchor",         // "auto" | "anchor"
                anchor: "workspaces",
                items: ["media", "workspaces", "dock", "clock", "wallpaper"]
            },
            right: ["screencap", "tray", "quicksettings"],
            disabled: ["dock"]
        })
    property var nightLight: ({
            scheduleEnabled: true,
            autoDarkMode: false,
            nightTemp: 4500,
            dayTemp: 6300,
            sunrise: "07:30",
            sunset: "21:00"
        })
    property var notifications: ({
            popupTimeout: 5,
            showAllMonitors: false,
            popupPosition: 0
        })
    property int dateFormat: 0
    property bool weekMonday: true
    property bool useFarenheit: false
    property bool verticalQSSliders: false
    property bool startLocked: false
    property bool useHyprlock: false
    property int osdPosition: 1
    property bool darkMode: true
    property string colorScheme: "scheme-tonal-spot"
    property int sourceColorIndex: 0
    property bool desktopClock: true
    property var screencap: ({
            blacklist: ["cts", "ocr"],
            screenshotPath: "~/.config/hypr/scripts/screenshot.sh",
            recordPath: "~/.config/hypr/scripts/record.sh",
            ctsPath: "~/.config/quickshell/isra/scripts/cts.sh",
            ocrPath: "~/.config/quickshell/isra/scripts/ocr.sh",
            songrecPath: "~/.config/quickshell/isra/scripts/songrec.sh"
        })
    property bool useAwww: false
    property var clock: ({
            layout: "vertical",
            hourSize: 100,
            minuteSize: 100,
            dateSize: 25,
            timeSpacing: -30,
            dateSpacing: -5,
            showDate: true,
            showSeconds: false,
            align: "left",
            fontFamily: "Google Sans Flex",
            hourWeight: 500,
            minuteWeight: 300,
            fontWidth: 100,
            fontRoundness: 0,
            subWidth: 100,
            subRoundness: 0,
            colorRole: "primary",
            subColorRole: "secondary",
            shadowBlur: 16,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0.2,
            manualPos: false,
            showDigitalInside: true,
            analogSize: 200,
            ringSides: 12,
            ringAmplitude: 4,
            outlineWidth: 2
        })
    property var weyes: ({
            enabled: false,
            x: 100,
            y: 100,
            width: 220,
            height: 120,
            tinted: false,
            mirror: true
        })
    property var clockPositions: ({})
    property var weyesPositions: ({})
    property bool checkUpdates: true
    property bool checkDeps: true
    property string githubRepo: "hireri/israshell"
    property bool allowNsfw: false
    property var pinnedApps: ["helium", "kitty", "dolphin"]

    function __defaults() {
        return {
            showSeconds: false,
            stackedSliders: false,
            hourFormat: 0,
            carouselSpeed: 30,
            fontFamily: "Inter",
            fontMonospace: "Roboto Mono",
            screenCorners: true,
            blurEffects: false,
            blurRadius: 50,
            blurOpacity: 0.65,
            cava: {
                enabled: false,
                bars: 30,
                position: 1,
                layout: "edges",
                renderType: "curve",
                curveType: "smooth",
                drawFill: true,
                drawStroke: true,
                colorStyle: "loudness",
                color: "primary",
                colorAlt: "error",
                height: 150,
                opacity: 0.3
            },
            workspaces: {
                compact: false,
                useIcons: true,
                style: 0
            },
            bar: {
                mode: 0,
                position: 0,
                transparency: 0,
                transparentPills: false,

                spinningCover: true,
                playerMode: 0,

                tintTrayIcons: false,
                trayBlacklist: ["spotify", "blueman", "Network"],

                left: ["activeWindow"],
                center: {
                    mode: "anchor",
                    anchor: "workspaces",
                    items: ["media", "workspaces", "dock", "clock", "wallpaper"]
                },
                right: ["screencap", "tray", "quicksettings"],
                disabled: ["dock"]
            },
            nightLight: {
                scheduleEnabled: true,
                autoDarkMode: false,
                nightTemp: 4500,
                dayTemp: 6300,
                sunrise: "07:30",
                sunset: "21:00"
            },
            notifications: {
                popupTimeout: 5,
                showAllMonitors: false,
                popupPosition: 0
            },
            dateFormat: 0,
            weekMonday: true,
            useFarenheit: false,
            verticalQSSliders: false,
            startLocked: false,
            useHyprlock: false,
            osdPosition: 1,
            darkMode: true,
            colorScheme: "scheme-tonal-spot",
            sourceColorIndex: 0,
            desktopClock: true,
            screencap: {
                blacklist: ["cts", "ocr"],
                screenshotPath: "~/.config/quickshell/isra/scripts/screenshot.sh",
                recordPath: "~/.config/quickshell/isra/scripts/record.sh",
                ctsPath: "~/.config/quickshell/isra/scripts/cts.sh",
                ocrPath: "~/.config/quickshell/isra/scripts/ocr.sh",
                songrecPath: "~/.config/quickshell/isra/scripts/songrec.sh"
            },
            clock: {
                layout: "vertical",
                hourSize: 100,
                minuteSize: 100,
                dateSize: 25,
                timeSpacing: -30,
                dateSpacing: -5,
                showDate: true,
                showSeconds: false,
                align: "left",
                fontFamily: "Google Sans Flex",
                hourWeight: 500,
                minuteWeight: 300,
                fontWidth: 100,
                fontRoundness: 0,
                subWidth: 100,
                subRoundness: 0,
                colorRole: "primary",
                subColorRole: "secondary",
                shadowBlur: 16,
                shadowX: 0,
                shadowY: 0,
                shadowOpacity: 0.2,
                shadowVisible: true,
                manualPos: false,
                showDigitalInside: true,
                analogSize: 200,
                ringSides: 12,
                ringAmplitude: 4,
                outlineWidth: 2
            },
            weyes: {
                enabled: false,
                x: 100,
                y: 100,
                width: 220,
                height: 120,
                tinted: false,
                mirror: true
            },
            useAwww: false,
            clockPositions: {},
            weyesPositions: {},
            checkUpdates: true,
            checkDeps: true,
            githubRepo: "hireri/israshell",
            allowNsfw: false,
            pinnedApps: ["helium", "kitty", "dolphin"]
        };
    }

    property bool _selfWrite: false

    function __apply(data) {
        const merged = __merge(data);
        for (const key in merged) {
            if (JSON.stringify(configRoot[key]) !== JSON.stringify(merged[key])) {
                configRoot[key] = merged[key];
            }
        }
    }

    function __isPlainObject(v) {
        return v !== null && typeof v === "object" && !Array.isArray(v);
    }

    function __deepMergeObj(defVal, dataVal) {
        if (!__isPlainObject(defVal))
            return dataVal !== undefined ? dataVal : defVal;
        if (!__isPlainObject(dataVal))
            return defVal;

        const result = {};
        for (const k in defVal) {
            result[k] = __deepMergeObj(defVal[k], dataVal[k]);
        }
        for (const k in dataVal) {
            if (!(k in result))
                result[k] = dataVal[k];
        }
        return result;
    }

    function __merge(data) {
        const defs = __defaults();
        const result = {};
        for (const key in defs) {
            result[key] = __deepMergeObj(defs[key], data[key]);
        }
        return result;
    }

    function __load() {
        try {
            const text = fileView.text();
            if (!text) {
                __apply({});
                return;
            }
            __apply(JSON.parse(text));
        } catch (e) {
            console.log("Config parse error:", e);
        }
    }

    function __write() {
        const data = {};
        for (const key in __defaults()) {
            data[key] = configRoot[key];
        }
        fileView.setText(JSON.stringify(data, null, 4));
    }

    function update(changes) {
        const data = {};
        for (const key in __defaults()) {
            data[key] = configRoot[key];
        }

        for (const key in changes) {
            if (key in data) {
                data[key] = changes[key];
            }
        }

        _selfWrite = true;
        fileView.setText(JSON.stringify(data, null, 4));

        __apply(data);
    }

    Timer {
        id: reloadDebouncer
        interval: 150
        onTriggered: fileView.reload()
    }

    FileView {
        id: fileView
        path: Quickshell.shellDir + "/config.json"
        watchChanges: true
        blockLoading: true
        Component.onCompleted: __load()
        onLoaded: {
            if (configRoot._selfWrite) {
                configRoot._selfWrite = false;
                return;
            }
            __load();
        }

        onFileChanged: reloadDebouncer.restart()
    }
}