pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.style
import qs.windows.components

Item {
    id: root

    readonly property string confPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/MangoHud/MangoHud.conf"
    readonly property var presets: [30, 60, 120, 144, 0]

    property int current: -1
    property bool installed: true

    implicitWidth: 300
    implicitHeight: column.implicitHeight

    function apply(fps) {
        setter.command = ["bash", Quickshell.shellDir + "/scripts/mangohud-fps.sh", String(fps)];
        setter.running = true;
    }

    function parseLimit(text) {
        const m = /^fps_limit=\s*(\d+)/m.exec(text);
        return m ? parseInt(m[1]) : -1;
    }

    FileView {
        id: conf
        path: root.confPath
        watchChanges: true
        printErrors: false
        onLoaded: root.current = root.parseLimit(conf.text())
        onLoadFailed: root.current = -1
        onFileChanged: conf.reload()
    }

    Process {
        id: setter
        onExited: conf.reload()
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v mangohud >/dev/null"]
        onExited: code => root.installed = code === 0
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: Localization.t("gameOverlay.fps_limit")
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.on_surface_variant
            }

            Text {
                text: root.current < 0 ? Localization.t("gameOverlay.fps_unset") : root.current === 0 ? Localization.t("gameOverlay.fps_unlimited") : Localization.t("gameOverlay.fps_value").arg(root.current)
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: Colors.md3.on_surface
            }
        }

        ChipRow {
            large: true
            fitWidth: column.width
            options: root.presets.map(v => ({
                        value: v,
                        label: v === 0 ? "∞" : String(v)
                    }))
            currentValue: root.current
            onSelected: v => root.apply(v)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            TextInputField {
                id: custom
                Layout.fillWidth: true
                placeholder: Localization.t("gameOverlay.fps_custom")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator {
                    bottom: 1
                    top: 1000
                }
                onCommitted: t => {
                    if (t === "")
                        return;
                    root.apply(parseInt(t));
                    custom.clear();
                }
            }

            OverlayButton {
                icon: "check"
                tip: Localization.t("gameOverlay.fps_apply")
                onClicked: custom.commit()
            }
        }

        Text {
            visible: !root.installed
            Layout.fillWidth: true
            text: Localization.t("gameOverlay.mangohud_missing")
            wrapMode: Text.WordWrap
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Colors.md3.error
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
