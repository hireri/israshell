//@ pragma UseQApplication
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: configRoot

    property bool spinningCover: true
    property bool showSeconds: false
    property int hourFormat: 0
    property int carouselSpeed: 30
    property bool transparentBar: false
    property string fontFamily: "Inter"
    property string fontMonospace: "Roboto Mono"
    property var trayBlacklist: ["spotify", "blueman", "Network"]
    property bool tintTrayIcons: false
    property int nightLightTemp: 4000
    property int dayLightTemp: 6500
    property bool floatingBar: false
    property bool huggingBar: true
    property bool screenCorners: true
    property int dateFormat: 0
    property int osdPosition: 1
    property bool darkMode: true
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

    function __defaults() {
        return {
            spinningCover: true,
            showSeconds: false,
            hourFormat: 0,
            carouselSpeed: 30,
            transparentBar: false,
            fontFamily: "Inter",
            fontMonospace: "Roboto Mono",
            trayBlacklist: ["spotify", "blueman", "Network"],
            tintTrayIcons: false,
            nightLightTemp: 4000,
            dayLightTemp: 6500,
            floatingBar: false,
            huggingBar: true,
            screenCorners: true,
            dateFormat: 0,
            osdPosition: 1,
            darkMode: true,
            desktopClock: true,
            screencapEnabled: true,
            screencap: {
                blacklist: ["cts", "ocr"],
                screenshotPath: "~/.config/hypr/scripts/screenshot.sh",
                recordPath: "~/.config/hypr/scripts/record.sh"
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
            clockPositions: {}
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
                __write();
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

    FileView {
        id: fileView
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true
        blockLoading: true
        Component.onCompleted: __load()
        onLoaded: __load()
        onFileChanged: {
            if (configRoot._selfWrite) {
                configRoot._selfWrite = false;
                return;
            }
            reload();
        }
    }
}
