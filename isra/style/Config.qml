pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: configRoot
    property bool showSeconds: false
    property int hourFormat: 0
    property int dateOrder: 0
    property int carouselSpeed: 30
    property string fontFamily: "Inter"
    property string fontMonospace: "Roboto Mono"
    property string language: "en_US"
    property string translationTone: "formal"
    property string translationProvider: ""
    property bool screenCorners: true
    property bool tintIcons: false
    property bool genericLauncherIcon: false
    property bool blurEffects: false
    property real blurOpacity: 1
    property bool desktopWidgetsBlur: false

    function dim(color) {
        return Qt.alpha(color, Math.max(0, Math.min(1, blurOpacity)));
    }

    function blurAllowed(visible) {
        return (visible === undefined ? true : visible) && blurEffects && !GameModeService.active;
    }

    readonly property bool desktopWidgetsBlurActive: desktopWidgetsBlur && blurAllowed(true)

    property bool showBarWeather: true
    property string timeFormat: ""
    property string dateFormat: ""
    property string cityName: ""

    property var background: ({
            transitionType: "crossfade", // "crossfade" | "wipe" | "circle" | "random"
            transitionDuration: 550,     // ms; converted to seconds for awww
            wipeAngle: 0,                // degrees; direction both wallpapers move during a wipe
            circleReverse: false,        // false = new wallpaper grows in; true = old wallpaper shrinks away
            transitionDisplacement: 20,  // percent; how far the wallpapers drift/scale during a transition
            videoSound: false,           // play audio for video wallpapers
            videoVolume: 0.5,            // 0..1
            muteOnMedia: false           // duck wallpaper audio while a media player is playing
        })
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
    property var sounds: ({
            enabled: true,
            theme: "freedesktop",
            volume: 0.7,
            notifications: true,
            volumeChange: true,
            screenshot: true,
            unlock: true,
            startup: true,
            lock: true,
            chargerPlug: true,
            batteryLow: true,
            localsend: true,
            bluetooth: true,
            muteDuringMedia: true,
            silentApps: ["discord"]
        })
    property var battery: ({
            lowBatteryNotify: true,
            lowBatteryThreshold: 20
        })
    property var workspaces: ({
        compact: false,
        useIcons: true,
        alwaysShowNumbers: false,
        style: 0
    })
    property var sysMonitor: ({
        style: 0,                          // 0 = icon+percent, 1 = radial pie, 2 = small progress bar
        metrics: ["cpu", "ram"],            // subset/order of: cpu, ram, gpu, temp, swap
        showPercent: true,
        smooth: true,
        colored: true,
        unifiedPill: false                 // false = each metric in its own pill, true = all metrics in one pill
    })
    property var quicksettings: ({
        icons: ["wifi", "bluetooth", "caffeine", "nightlight", "dnd"],  // subset/order of: wifi, bluetooth, sound, caffeine, nightlight, dnd, recording, vpn, mic, screenshare, traffic, dns, gamemode, powerprofile. "sound" absent = shows only while muted (like the old always-there mute icon); include it to keep it always visible.
        outline: false                     // true = outline style instead of filled, for icons that support it
    })
    function __barDefaults() {
        const layout = WidgetService.defaultLayout();
        return {
            mode: 0,                    // 0 = hugging, 1 = rect,   2 = floating
            position: 0,                // 0 = top,     1 = bottom
            transparency: 1,            // 1 = tinted, 2 = full transparency
            transparentPills: false,

            showClock: true,
            showDate: true,

            spinningCover: true,
            playerMode: 0,
            playerRing: false,

            trayBlacklist: ["spotify", "blueman", "Network"],

            left: layout.left,
            center: {
                mode: "anchor",         // "auto" | "anchor"
                anchor: "workspaces",
                items: layout.center
            },
            right: layout.right,
            disabled: layout.disabled
        };
    }

    property var bar: __barDefaults()
    function __floatingDockDefaults() {
        return {
            enabled: false,
            edge: 1,              // 0 = top, 1 = bottom, 2 = left, 3 = right
            smartHide: false,
            exclusiveZone: false,
            showLauncher: true,
            showTrash: false,
            showMusicPlayer: false,
            iconSize: 32
        };
    }
    property var floatingDock: __floatingDockDefaults()

    readonly property int floatingDockThickness: floatingDock.iconSize + 32

    function __barDockEdgeConflict() {
        if (!floatingDock.enabled) return false;
        if (floatingDock.edge === 0 && bar.position === 0) return true;
        if (floatingDock.edge === 1 && bar.position === 1) return true;
        return false;
    }

    function __resolveBarMovedConflict() {
        if (!__barDockEdgeConflict()) return;
        configRoot.update({ floatingDock: Object.assign({}, floatingDock, { edge: floatingDock.edge === 0 ? 1 : 0 }) });
    }

    function __resolveDockMovedConflict() {
        if (!__barDockEdgeConflict()) return;
        configRoot.update({ bar: Object.assign({}, bar, { position: bar.position === 0 ? 1 : 0 }) });
    }

    onBarChanged: Qt.callLater(__resolveBarMovedConflict)
    onFloatingDockChanged: Qt.callLater(__resolveDockMovedConflict)

    function __qsTilesDefaults() {
        return QsTileService.defaultLayout();
    }
    property var quickSettingsTiles: __qsTilesDefaults()
    property var nightLight: ({
            scheduleEnabled: true,
            autoDarkMode: false,
            autoSunTimes: false,
            nightTemp: 4500,
            dayTemp: 6300,
            sunrise: "07:30",
            sunset: "21:00"
        })
    property var bedtime: ({
            enableDarkMode: true,
            dimWallpaper: true,
            dimAmount: 0.35,
            grayscaleWallpaper: false,
            grayscaleTheme: false,
            stopVideo: true,
            muteSounds: true
        })
    property var notifications: ({
            popupTimeout: 5,
            showAllMonitors: false,
            popupFollowBar: true,
            popupPosition: 1,
            network: true,
            bluetooth: true
        })
    property var localsend: ({
            enabled: false,
            notifyOnReceive: true,
            deviceType: "desktop",
            alias: "",
            pin: "",
            encryption: true
        })
    property var dns: ({
            enabled: false,
            provider: "cloudflare"
        })
    property var aiAssistant: ({
            enabled: true,
            provider: "gemini",
            notifyOnFinish: false,
            systemPrompt: "You are a helpful assistant embedded in the user's Linux desktop shell. Current time: {time} on {date}. The user is running {distro} with the {compositor} compositor, logged in as {user}. Keep answers concise and practical unless asked to go deeper.",
            providers: {
                gemini: {
                    apiType: "gemini",
                    model: "gemini-flash-latest",
                    endpoint: "https://generativelanguage.googleapis.com/v1beta",
                    requiresAuth: true,
                    supportsTools: true,
                    supportsVision: true
                },
                openai: {
                    apiType: "openai",
                    model: "gpt-4o-mini",
                    endpoint: "https://api.openai.com/v1",
                    requiresAuth: true,
                    supportsTools: true,
                    supportsVision: true
                },
                ollama: {
                    apiType: "ollama",
                    model: "llama3.2",
                    endpoint: "http://localhost:11434",
                    requiresAuth: false,
                    supportsTools: false,
                    supportsVision: false
                }
            }
        })
    property bool weekMonday: true
    property bool useFahrenheit: false
    property bool verticalQSSliders: false
    property bool linkMonitorBrightness: false
    property bool startLocked: false
    property bool useHyprlock: false
    property int osdPosition: 1
    property bool osdFollowBar: false
    property bool darkMode: true
    property string colorScheme: "scheme-tonal-spot"
    property int sourceColorIndex: 0
    property bool desktopClock: true
    property var screencap: ({
            blacklist: ["cts", "ocr"],
            order: ["wallpaper", "screenshot", "cts", "ocr", "colorpicker", "localsend", "songrec", "record"],
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
    property var neko: ({
            enabled: false,
            size: 32,
            speed: 10,
            onTop: false,
            sprite: "oneko"
        })
    property bool activateLinux: false
    property var lockscreen: ({
            dotShape: "roundedSquare"  // "roundedSquare" | "circle" | "material"
        })
    property var clockPositions: ({})
    property var desktopWidgets: []
    property var weather: ({
            coloredIcons: false
        })
    property var desktopGrid: ({
            cellSize: 50,
            gutter: 8,
            margin: 24
        })
    property var pomodoro: ({
            running: false,
            phaseIndex: 0,
            endTimestamp: 0,
            remainingMs: 1500000,
            steps: [
                { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                { focusMinutes: 25, breakType: "long_break", breakMinutes: 15 }
            ]
        })
    property bool checkUpdates: true
    property bool checkDeps: true
    property string githubRepo: "hireri/israshell"
    property bool allowNsfw: false
    property var pinnedApps: ["helium", "kitty", "dolphin"]

    function __pinnedWallpaperDirDefaults() {
        const home = Quickshell.env("HOME");
        return [home + "/Downloads"];
    }
    property var pinnedWallpaperDirs: __pinnedWallpaperDirDefaults()

    function __defaults() {
        return {
            showSeconds: false,
            hourFormat: 0,
            dateOrder: 0,
            carouselSpeed: 30,
            fontFamily: "Inter",
            fontMonospace: "Roboto Mono",
            language: "en_US",
            translationTone: "formal",
            translationProvider: "",
            screenCorners: true,
            tintIcons: false,
            genericLauncherIcon: false,
            blurEffects: false,
            blurOpacity: 1,
            desktopWidgetsBlur: false,

            showBarWeather: true,
            timeFormat: "",
            dateFormat: "",
            cityName: "",

            background: {
                transitionType: "crossfade",
                transitionDuration: 550,
                wipeAngle: 0,
                circleReverse: false,
                transitionDisplacement: 20,
                videoSound: false,
                videoVolume: 0.5,
                muteOnMedia: false
            },
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
                alwaysShowNumbers: false,
                style: 0
            },
            sounds: {
                enabled: true,
                theme: "freedesktop",
                volume: 0.7,
                notifications: true,
                volumeChange: true,
                screenshot: true,
                unlock: true,
                startup: true,
                lock: true,
                chargerPlug: true,
                batteryLow: true,
                localsend: true,
                bluetooth: true,
                muteDuringMedia: true,
                silentApps: ["discord"]
            },
            battery: {
                lowBatteryNotify: true,
                lowBatteryThreshold: 20
            },
            sysMonitor: {
                style: 0,
                metrics: ["cpu", "ram"],
                showPercent: true,
                smooth: true,
                colored: true,
                unifiedPill: false
            },
            quicksettings: {
                icons: ["wifi", "bluetooth", "caffeine", "nightlight", "dnd"],
                outline: false
            },
            bar: __barDefaults(),
            floatingDock: __floatingDockDefaults(),
            quickSettingsTiles: __qsTilesDefaults(),
            nightLight: {
                scheduleEnabled: true,
                autoDarkMode: false,
                autoSunTimes: false,
                nightTemp: 4500,
                dayTemp: 6300,
                sunrise: "07:30",
                sunset: "21:00"
            },
            bedtime: {
                enableDarkMode: true,
                dimWallpaper: true,
                dimAmount: 0.35,
                grayscaleWallpaper: false,
                grayscaleTheme: false,
                stopVideo: true,
                muteSounds: true
            },
            notifications: {
                popupTimeout: 5,
                showAllMonitors: false,
                popupFollowBar: true,
                popupPosition: 1,
                network: true,
                bluetooth: true
            },
            localsend: {
                enabled: false,
                notifyOnReceive: true,
                deviceType: "desktop",
                alias: "",
                pin: "",
                encryption: true
            },
            dns: {
                enabled: false,
                provider: "cloudflare"
            },
            aiAssistant: {
                enabled: true,
                provider: "gemini",
                notifyOnFinish: false,
                systemPrompt: "You are a helpful assistant embedded in the user's Linux desktop shell. Current time: {time} on {date}. The user is running {distro} with the {compositor} compositor, logged in as {user}. Keep answers concise and practical unless asked to go deeper.",
                providers: {
                    gemini: {
                        apiType: "gemini",
                        model: "gemini-flash-latest",
                        endpoint: "https://generativelanguage.googleapis.com/v1beta",
                        requiresAuth: true,
                        supportsTools: true,
                        supportsVision: true
                    },
                    openai: {
                        apiType: "openai",
                        model: "gpt-4o-mini",
                        endpoint: "https://api.openai.com/v1",
                        requiresAuth: true,
                        supportsTools: true,
                        supportsVision: true
                    },
                    ollama: {
                        apiType: "ollama",
                        model: "llama3.2",
                        endpoint: "http://localhost:11434",
                        requiresAuth: false,
                        supportsTools: false,
                        supportsVision: false
                    }
                }
            },
            weekMonday: true,
            useFahrenheit: false,
            verticalQSSliders: false,
            linkMonitorBrightness: false,
            startLocked: false,
            useHyprlock: false,
            osdPosition: 1,
            osdFollowBar: false,
            darkMode: true,
            colorScheme: "scheme-tonal-spot",
            sourceColorIndex: 0,
            desktopClock: true,
            screencap: {
                blacklist: ["cts", "ocr"],
                order: ["wallpaper", "screenshot", "cts", "ocr", "colorpicker", "localsend", "songrec", "record"],
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
            neko: {
                enabled: false,
                size: 32,
                speed: 10,
                onTop: false,
                sprite: "oneko"
            },
            activateLinux: false,
            lockscreen: {
                dotShape: "roundedSquare"
            },
            useAwww: false,
            clockPositions: {},
            desktopWidgets: [],
            weather: {
                coloredIcons: false
            },
            desktopGrid: {
                cellSize: 50,
                gutter: 8,
                margin: 24
            },
            pomodoro: {
                running: false,
                phaseIndex: 0,
                endTimestamp: 0,
                remainingMs: 1500000,
                steps: [
                    { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                    { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                    { focusMinutes: 25, breakType: "short_break", breakMinutes: 5 },
                    { focusMinutes: 25, breakType: "long_break", breakMinutes: 15 }
                ]
            },
            checkUpdates: true,
            checkDeps: true,
            githubRepo: "hireri/israshell",
            allowNsfw: false,
            pinnedApps: ["helium", "kitty", "dolphin"],
            pinnedWallpaperDirs: __pinnedWallpaperDirDefaults()
        };
    }

    property bool _selfWrite: false

    readonly property string configDir: Quickshell.env("HOME") + "/.config/israshell"
    readonly property string configPath: configDir + "/config.json"

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

        if (data.tintIcons === undefined && data.bar && data.bar.tintTrayIcons !== undefined)
            result.tintIcons = data.bar.tintTrayIcons;

        if (result.bar)
            result.bar = WidgetService.reconcile(result.bar);
        if (result.quickSettingsTiles)
            result.quickSettingsTiles = QsTileService.reconcile(result.quickSettingsTiles);

        if (result.desktopWidgets) {
            const legacyTinted = data.weyes?.tinted ?? false;
            const migrated = result.desktopWidgets.map(w => {
                if (!w || w.type !== "weyes" || (w.data && w.data.tinted !== undefined))
                    return w;
                return Object.assign({}, w, { data: Object.assign({}, w.data, { tinted: legacyTinted }) });
            });
            result.desktopWidgets = DesktopWidgetService.reconcile(migrated);
        }

        if (result.pomodoro) {
            const rawSteps = data.pomodoro && data.pomodoro.steps;
            if (Array.isArray(rawSteps) && rawSteps.length > 0 && rawSteps[0] && rawSteps[0].focusMinutes === undefined && rawSteps[0].type !== undefined) {
                const migrated = [];
                for (let i = 0; i < rawSteps.length; i += 2) {
                    const focusPhase = rawSteps[i];
                    const breakPhase = rawSteps[i + 1];
                    migrated.push({
                        focusMinutes: focusPhase ? focusPhase.minutes : 25,
                        breakType: (breakPhase && breakPhase.type === "long_break") ? "long_break" : "short_break",
                        breakMinutes: breakPhase ? breakPhase.minutes : 5
                    });
                }
                result.pomodoro = Object.assign({}, result.pomodoro, { steps: migrated, phaseIndex: 0 });
            }
        }

        if (result.notifications) {
            const rawPopupPosition = data.notifications && data.notifications.popupPosition;
            const followBar = (data.notifications && data.notifications.popupFollowBar !== undefined)
                ? data.notifications.popupFollowBar
                : (rawPopupPosition === undefined || rawPopupPosition === 0);
            result.notifications = Object.assign({}, result.notifications, {
                popupFollowBar: followBar,
                popupPosition: (rawPopupPosition === 1 || rawPopupPosition === 2) ? rawPopupPosition : 1
            });
        }

        if (result.sounds && data.sounds && data.sounds.lockUnlock !== undefined && data.sounds.unlock === undefined)
            result.sounds = Object.assign({}, result.sounds, { unlock: data.sounds.lockUnlock });

        if (result.aiAssistant)
            result.aiAssistant = Object.assign({}, result.aiAssistant, {
                providers: (data.aiAssistant && data.aiAssistant.providers) ? data.aiAssistant.providers : defs.aiAssistant.providers
            });

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

        __apply(data);

        _selfWrite = true;
        writeDebouncer.restart();
    }

    function resetToDefaults() {
        update(__defaults());
    }

    Timer {
        id: reloadDebouncer
        interval: 150
        onTriggered: fileView.reload()
    }

    Timer {
        id: writeDebouncer
        interval: 150
        onTriggered: configRoot.__write()
    }

    FileView {
        id: fileView
        path: configRoot.configPath
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