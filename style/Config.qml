pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: configRoot

    property var ai: ({
            name: "LLM",
            systemPrompt: "You are a **helpful** desktop integrated assistant. User is on {distro}, using {compositor} compositor. It is {date}, {time}.",
            temperature: 0.7,
            tools: ["memory", "ddg-search"],
            providers: [
                {
                    id: "lmstudio",
                    type: "openai",
                    label: "LM Studio",
                    endpoint: "http://localhost:1234/v1",
                    model: "llama-3-14b-instruct-v1",
                    apiKey: ""
                }
            ],
            activeProvider: "lmstudio"
        })
    property bool spinningCover: true
    property bool showSeconds: false
    property int hourFormat: 0
    property int carouselSpeed: 30
    property bool transparentBar: false
    property string fontFamily: "Inter"
    property string fontMonospace: "Roboto Mono"
    property var trayBlacklist: ["spotify", "blueman", "Network"]
    property bool tintTrayIcons: false
    property bool floatingBar: false
    property bool huggingBar: true
    property bool screenCorners: true
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
            showAllMonitors: false
        })
    property int dateFormat: 0
    property int osdPosition: 1
    property bool darkMode: true
    property string colorScheme: "scheme-tonal-spot"
    property bool desktopClock: true
    property bool screencapEnabled: true
    property var screencap: ({
            blacklist: ["cts", "ocr"],
            screenshotPath: "~/.config/hypr/scripts/screenshot.sh",
            recordPath: "~/.config/hypr/scripts/record.sh"
        })
    property var clock: ({
            fontFamily: "",
            layout: "vertical",
            showSeconds: false,
            hourSize: 100,
            minuteSize: 100,
            hourWeight: 500,
            minuteWeight: 500,
            dateSize: 25,
            timeSpacing: -30,
            dateSpacing: -5,
            showDate: true,
            align: "left",
            colorRole: "primary",
            subColorRole: "secondary",
            shadowBlur: 16
        })
    property var clockPositions: ({})
    property bool allowNsfw: false

    function __defaults() {
        return {
            ai: {
                name: "LLM",
                systemPrompt: "You are a **helpful** desktop integrated assistant. User is on {distro}, using {compositor} compositor. It is {date}, {time}.",
                temperature: 0.7,
                tools: ["memory", "ddg-search"],
                providers: [
                    {
                        id: "lmstudio",
                        type: "openai",
                        label: "LM Studio",
                        endpoint: "http://localhost:1234/v1",
                        model: "llama-3-14b-instruct-v1",
                        apiKey: ""
                    }
                ],
                activeProvider: "lmstudio"
            },
            spinningCover: true,
            showSeconds: false,
            hourFormat: 0,
            carouselSpeed: 30,
            transparentBar: false,
            fontFamily: "Inter",
            fontMonospace: "Roboto Mono",
            trayBlacklist: ["spotify", "blueman", "Network"],
            tintTrayIcons: false,
            floatingBar: false,
            huggingBar: true,
            screenCorners: true,
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
                showAllMonitors: false
            },
            dateFormat: 0,
            osdPosition: 1,
            darkMode: true,
            colorScheme: "scheme-tonal-spot",
            desktopClock: true,
            screencapEnabled: true,
            screencap: {
                blacklist: ["cts", "ocr"],
                screenshotPath: "~/.config/quickshell/scripts/screenshot.sh",
                recordPath: "~/.config/quickshell/scripts/record.sh",
                ctsPath: "~/.config/quickshell/scripts/cts.sh",
                ocrPath: "~/.config/quickshell/scripts/ocr.sh",
                songrecPath: "~/.config/quickshell/scripts/songrec.sh"
            },
            clock: {
                fontFamily: "",
                layout: "vertical",
                showSeconds: false,
                hourSize: 100,
                minuteSize: 100,
                hourWeight: 500,
                minuteWeight: 500,
                dateSize: 25,
                timeSpacing: -30,
                dateSpacing: -5,
                showDate: true,
                align: "left",
                colorRole: "primary",
                subColorRole: "secondary",
                shadowBlur: 16
            },
            clockPositions: {},
            allowNsfw: false
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

    function __merge(data) {
        const defs = __defaults();
        const result = {};
        for (const key in defs) {
            result[key] = data[key] !== undefined ? data[key] : defs[key];
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
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
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
