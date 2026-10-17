pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.style
import qs.services
import qs.windows.components
import qs.components
import qs.icons

PageBase {
    pageId: "system"
    id: pageRoot
    title: Localization.t("settingsWindow.system")
    subtitle: Localization.t("systemPage.about_and_script_paths")

    function setVoice(key, value) {
        Config.update({
            voice: Object.assign({}, Config.voice, {
                [key]: value
            })
        });
    }

    readonly property var voiceLanguages: {
        const codes = "en zh de es ru ko fr ja pt tr pl ca nl ar sv it id hi fi vi he uk el ms cs ro da hu ta no th ur hr bg lt la mi ml cy sk te fa lv bn sr az sl kn et mk br eu is hy ne mn bs kk sq sw gl mr pa si km sn yo so af oc ka be tg sd gu am yi lo uz fo ht ps tk nn mt sa lb my bo tl mg as tt haw ln ha ba jw su yue".split(" ");
        const own = {
            en: "English",
            es: "Español",
            zh: "中文",
            yue: "粵語"
        };
        const opts = codes.map(c => {
            const loc = Qt.locale(c === "jw" ? "jv" : c);
            let name = own[c] ?? (loc.name !== "C" ? loc.nativeLanguageName : c);
            if (/^[\u0000-\u052f]/.test(name))
                name = name.charAt(0).toUpperCase() + name.slice(1);
            return {
                label: name + " (" + c + ")",
                value: c
            };
        });
        opts.sort((a, b) => a.label.localeCompare(b.label));
        return [{
                label: Localization.t("voicePage.language_auto"),
                value: "auto"
            }].concat(opts);
    }

    readonly property var dotMaterialShapes: ["clover4", "arrow", "pill", "softBurst", "diamond", "clamShell", "pentagon"]

    Component {
        id: dotShapeSquarePreview
        Rectangle {
            width: 14
            height: 14
            radius: 3
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: dotShapeCirclePreview
        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: dotShapeMaterialPreview
        MaterialShape {
            shapeSize: 14
            color: Colors.md3.on_surface_variant
            cycleInterval: 2000
            shapes: pageRoot.dotMaterialShapes
        }
    }

    readonly property var systemFontsModel: {
        var families = Qt.fontFamilies();
        var uniqueFamilies = families.filter(function(item, pos, self) {
            return self.indexOf(item) === pos;
        });
        uniqueFamilies.sort(function(a, b) {
            return a.localeCompare(b);
        });
        return uniqueFamilies.map(function(family) {
            return {
                label: family,
                value: family
            };
        });
    }

    onActiveChanged: {
        if (!active)
            return;
        Updater.checkNow();
        VoiceService.refresh();
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 24
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.bottomMargin: 8
            spacing: 32

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                IconImage {
                    source: Quickshell.iconPath(SystemInfo.logo, "distributor-logo-linux")
                    implicitSize: 96
                    smooth: true
                }

                Text {
                    text: SystemInfo.distroName
                    font.family: Config.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Bold
                    color: Colors.md3.on_surface
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                font.family: Config.fontMonospace
                font.pixelSize: 13
                color: Colors.md3.on_surface_variant
                text: "<b><font color='" + Colors.md3.on_surface + "'>" + Localization.t("systemPage.kernel") + "</font></b> " + SystemInfo.kernel + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>" + Localization.t("systemPage.session") + "</font></b> " + SystemInfo.session + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>" + Localization.t("systemPage.uptime") + "</font></b> " + SystemInfo.uptime
                textFormat: Text.RichText
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: 24
            color: Colors.md3.primary

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                Image {
                    source: "/usr/share/icons/hicolor/scalable/apps/org.quickshell.svg"
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: "Israshell " + (Updater.currentVersion || "...")
                        font.family: Config.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: Colors.md3.on_primary
                    }

                    Text {
                        text: SystemInfo.quickshellVersion
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                        opacity: 0.8
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 40
                    implicitWidth: updateLbl.implicitWidth + 32
                    radius: 20
                    visible: Updater.updateAvailable || Updater.applying
                    opacity: Updater.applying ? 0.6 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    color: Qt.rgba(Qt.color(Colors.md3.on_primary).r, Qt.color(Colors.md3.on_primary).g, Qt.color(Colors.md3.on_primary).b, 0.2)

                    border.width: 1.5
                    border.color: Colors.md3.on_primary

                    Text {
                        id: updateLbl
                        anchors.centerIn: parent
                        text: Updater.applying ? Localization.t("systemPage.updating") : "↑ " + Updater.latestVersion
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.md3.on_primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !Updater.applying
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: Updater.applyUpdate()
                    }

                    Tooltip {
                        text: Localization.t("systemPage.tooltip_install_update")
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 40
                    implicitWidth: ghLbl.implicitWidth + 32
                    radius: 20
                    color: Colors.md3.on_primary

                    Text {
                        id: ghLbl
                        anchors.centerIn: parent
                        text: Localization.t("systemPage.github")
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.md3.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/" + Config.githubRepo)
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 4
            rowSpacing: 4

            HardwareCard {
                labelText: Localization.t("sysMonitor.cpu")
                valueText: SystemInfo.cpu
                topLeftRadius: 16
                topRightRadius: 8
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: Localization.t("sysMonitor.gpu")
                valueText: SystemInfo.gpu
                topLeftRadius: 8
                topRightRadius: 16
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: Localization.t("systemPage.memory")
                valueText: SystemInfo.memory
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 16
                bottomRightRadius: 4
            }
            HardwareCard {
                labelText: Localization.t("systemPage.motherboard")
                valueText: SystemInfo.motherboard
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 4
                bottomRightRadius: 16
            }
        }

        SectionCard {
            label: Localization.t("systemApp.title")
            Layout.fillWidth: true

            SettingRow {
                label: Localization.t("systemApp.shortcut_title")
                sublabel: Localization.t("systemApp.shortcut_sub")

                ActionButton {
                    icon: "arrow-outward"
                    label: Localization.t("systemApp.open")
                    onClicked: Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "system", "open", "overview"])
                }
            }
        }

        SectionCard {
            label: Localization.t("systemPage.updates")
            Layout.fillWidth: true

            SettingSwitch {
                label: Localization.t("systemPage.check_for_updates")
                sublabel: Localization.t("systemPage.poll_github_for_new_releases")
                checked: Config.checkUpdates
                onToggled: v => Config.update({
                        checkUpdates: v
                    })
            }

            SettingSwitch {
                isLast: true
                label: Localization.t("systemPage.check_dependencies")
                sublabel: Localization.t("systemPage.warn_about_missing_packages_on")
                checked: Config.checkDeps
                onToggled: v => Config.update({
                        checkDeps: v
                    })
            }
        }

        SectionCard {
            label: Localization.t("systemPage.presets")
            Layout.fillWidth: true

            SettingRow {
                label: Localization.t("systemPage.save_preset")
                sublabel: Localization.t("systemPage.snapshot_your_config_to_config")

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: saveLbl.implicitWidth + 24
                    radius: 16
                    color: Colors.md3.primary
                    opacity: ConfigPresetService.busy ? 0.6 : 1.0

                    Text {
                        id: saveLbl
                        anchors.centerIn: parent
                        text: ConfigPresetService.busy ? Localization.t("systemPage.saving") : Localization.t("systemPage.save_preset")
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !ConfigPresetService.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ConfigPresetService.savePreset()
                    }
                }
            }

            Text {
                visible: ConfigPresetService.entries.length === 0
                text: Localization.t("systemPage.no_presets_yet")
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.outline
                leftPadding: 18
                bottomPadding: 12
                topPadding: 4
            }

            Text {
                visible: ConfigPresetService.statusMessage !== ""
                text: ConfigPresetService.statusMessage
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: ConfigPresetService.statusIsError ? Colors.md3.error : Colors.md3.outline
                leftPadding: 18
                rightPadding: 18
                bottomPadding: 8
                wrapMode: Text.WordWrap
                width: parent?.width ?? 0
            }

            Repeater {
                id: presetRepeater
                model: ConfigPresetService.entries

                delegate: Item {
                    id: presetRow
                    required property var modelData
                    required property int index

                    implicitWidth: parent?.width ?? 0
                    implicitHeight: 52

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 18
                            rightMargin: 14
                        }
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: presetRow.modelData.name
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: Colors.md3.on_surface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: Localization.t("systemPage.created_value").arg((ConfigPresetService.nowTick, ConfigPresetService.relativeTime(presetRow.modelData.mtime)))
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: Colors.md3.outline
                            }
                        }

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                height: 28
                                width: applyTxt.implicitWidth + 16
                                radius: 14
                                color: (Config.dim(Colors.md3.surface_container_high))

                                Text {
                                    id: applyTxt
                                    anchors.centerIn: parent
                                    text: Localization.t("systemPage.apply")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Colors.md3.on_surface_variant
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ConfigPresetService.applyPreset(presetRow.modelData.path)
                                }

                                Tooltip {
                                    text: Localization.t("systemPage.tooltip_apply_preset")
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: (Config.dim(Colors.md3.surface_container_high))

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    font.pixelSize: 15
                                    color: Colors.md3.outline
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ConfigPresetService.deletePreset(presetRow.modelData.path)
                                }
                            }
                        }
                    }
                }
            }

            SettingRow {
                label: Localization.t("systemPage.regenerate_config")
                sublabel: Localization.t("systemPage.reset_every_setting_to_its")

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: regenLbl.implicitWidth + 24
                    radius: 16
                    color: Colors.md3.error

                    Text {
                        id: regenLbl
                        anchors.centerIn: parent
                        text: Localization.t("systemPage.regenerate")
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.md3.on_error
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.resetToDefaults()
                    }
                }
            }
        }

        SectionCard {
            label: Localization.t("systemPage.system_integration")
            Layout.fillWidth: true

            SettingSwitch {
                label: Localization.t("systemPage.start_locked")
                sublabel: Localization.t("systemPage.show_lockscreen_when_shell_starts")
                checked: Config.startLocked
                onToggled: v => Config.update({ startLocked: v })
            }

            SettingSwitch {
                label: Localization.t("systemPage.use_hyprlock")
                sublabel: Localization.t("systemPage.delegate_locking_to_hyprlock_instead")
                tooltip: Localization.t("systemPage.tooltip_use_hyprlock")
                checked: Config.useHyprlock
                onToggled: v => Config.update({ useHyprlock: v })
            }

            SettingSwitch {
                label: Localization.t("systemPage.media_art_lockscreen_background")
                sublabel: Localization.t("systemPage.use_the_playing_tracks_album_art")
                checked: Config.lockscreen.artWallpaper ?? false
                onToggled: v => Config.update({
                    lockscreen: Object.assign({}, Config.lockscreen, {
                        artWallpaper: v
                    })
                })
            }

            SettingSlider {
                label: Localization.t("systemPage.lockscreen_blur")
                sublabel: Localization.t("systemPage.how_blurred_the_lockscreen_background_is")
                enabled: Config.blurEffects
                opacity: enabled ? 1.0 : 0.4
                from: 0
                to: 1
                stepSize: 0.05
                decimals: 2
                value: Config.lockscreen.blurAmount ?? 1
                onMoved: v => Config.update({
                        lockscreen: Object.assign({}, Config.lockscreen, {
                            blurAmount: v
                        })
                    })
            }

            SettingChips {
                isLast: true
                label: Localization.t("systemPage.password_dot_shape")
                sublabel: Localization.t("systemPage.shape_of_the_lockscreen_input")
                options: [
                    { label: "", value: "roundedSquare", icon: dotShapeSquarePreview },
                    { label: "", value: "circle", icon: dotShapeCirclePreview },
                    { label: "", value: "material", icon: dotShapeMaterialPreview }
                ]
                currentValue: Config.lockscreen.dotShape
                onSelected: v => Config.update({
                    lockscreen: Object.assign({}, Config.lockscreen, {
                        dotShape: v
                    })
                })
            }
        }

        SectionCard {
            label: Localization.t("systemPage.battery")
            Layout.fillWidth: true

            SettingSwitch {
                label: Localization.t("systemPage.low_battery_notify")
                sublabel: Localization.t("systemPage.warn_when_battery_is_low")
                tooltip: Localization.t("systemPage.tooltip_battery_needs_battery")
                enabled: BatteryService.hasBattery
                opacity: enabled ? 1.0 : 0.4
                checked: Config.battery.lowBatteryNotify
                onToggled: v => Config.update({
                    battery: Object.assign({}, Config.battery, {
                        lowBatteryNotify: v
                    })
                })
            }

            SettingSlider {
                isLast: true
                label: Localization.t("systemPage.low_battery_threshold")
                tooltip: Localization.t("systemPage.tooltip_low_battery_threshold")
                enabled: BatteryService.hasBattery && Config.battery.lowBatteryNotify
                opacity: enabled ? 1.0 : 0.4
                from: 5
                to: 50
                stepSize: 1
                unit: "%"
                value: Config.battery.lowBatteryThreshold
                onMoved: v => Config.update({
                    battery: Object.assign({}, Config.battery, {
                        lowBatteryThreshold: v
                    })
                })
            }
        }

        SectionCard {
            label: Localization.t("systemPage.license")
            Layout.fillWidth: true

            SettingSwitch {
                isLast: true
                label: Localization.t("systemPage.activate_license")
                sublabel: Localization.t("systemPage.israshell_is_not_activated_activate")
                checked: !Config.activateLinux
                onToggled: v => Config.update({
                        activateLinux: !v
                    })
            }
        }

        SectionCard {
            label: Localization.t("qsTileService.localsend")
            Layout.fillWidth: true

            SettingSwitch {
                label: Localization.t("backgroundPage.enable")
                sublabel: Localization.t("systemPage.localsend_discoverable_desc")
                tooltip: Localization.t("systemPage.tooltip_localsend_unavailable")
                checked: LocalSendService.ready
                enabled: LocalSendService.reachable
                onToggled: v => LocalSendService.setEnabled(v)
            }

            SettingInput {
                label: Localization.t("systemPage.device_name")
                sublabel: Localization.t("systemPage.how_this_device_appears_to")
                value: Config.localsend.alias ?? ""
                fieldWidth: 160
                onCommitted: v => LocalSendService.setAlias(v)
            }

            SettingSwitch {
                label: Localization.t("systemPage.encryption") || "Encryption"
                sublabel: Localization.t("systemPage.localsend_encryption_desc") || "Encrypt file transfers (HTTPS)"
                tooltip: Localization.t("systemPage.tooltip_encryption_after_transfer")
                checked: LocalSendService.encryptionTarget
                enabled: LocalSendService.reachable
                onToggled: v => LocalSendService.setEncryption(v)
            }

            SettingInput {
                label: Localization.t("systemPage.pin") || "PIN"
                sublabel: Localization.t("systemPage.localsend_pin_desc") || "Require a PIN to receive files"
                value: Config.localsend.pin ?? ""
                fieldWidth: 100
                onCommitted: v => LocalSendService.setPin(v)
            }

            SettingSwitch {
                isLast: true
                label: Localization.t("systemPage.notify_on_receive")
                sublabel: Localization.t("systemPage.show_a_desktop_notification_for")
                checked: Config.localsend.notifyOnReceive
                onToggled: v => Config.update({
                        localsend: Object.assign({}, Config.localsend, {
                            notifyOnReceive: v
                        })
                    })
            }
        }

        SectionCard {
            label: Localization.t("voicePage.title")
            Layout.fillWidth: true

            SettingRow {
                label: Localization.t("voicePage.engine")
                sublabel: {
                    const v = VoiceService;
                    if (v.installStep === "download")
                        return Localization.t("voicePage.engine_fetching").arg(Math.round(v.installProgress * 100));
                    if (v.installStep === "error")
                        return v.installError || Localization.t("voice.failed");
                    if (Config.voice.serverPath !== "")
                        return Localization.t(v.serverFound ? "voicePage.engine_custom" : "voicePage.engine_custom_missing");
                    if (v.engineVersion !== "")
                        return "whisper.cpp " + v.engineVersion.split("+")[0] + " · " + Localization.t("voicePage.engine_vulkan");
                    return Localization.t("voicePage.engine_missing");
                }

                WavyProgress {
                    anchors.verticalCenter: parent?.verticalCenter
                    visible: VoiceService.installStep === "download"
                    width: 110
                    value: VoiceService.installProgress
                }

                ActionButton {
                    anchors.verticalCenter: parent?.verticalCenter
                    visible: VoiceService.installStep !== "download" && Config.voice.serverPath === "" && VoiceService.engineVersion !== VoiceService.engineTag
                    icon: VoiceService.engineVersion !== "" ? "restart" : "download-for-offline"
                    label: Localization.t(VoiceService.installStep === "error" ? "voicePage.retry" : VoiceService.engineVersion !== "" ? "voicePage.update" : "voicePage.install")
                    onClicked: VoiceService.installEngine()
                }
            }

            SettingRow {
                id: modelRow
                stack: true
                label: Localization.t("voicePage.model")
                sublabel: Config.voice.modelPath !== "" ? Localization.t("voicePage.model_custom") : Localization.t("voicePage.model_sub")

                Column {
                    width: modelRow.contentWidth
                    topPadding: 2
                    spacing: 6

                    Repeater {
                        model: VoiceService.models

                        delegate: Rectangle {
                            id: tile
                            required property var modelData

                            readonly property bool have: VoiceService.downloaded.includes(modelData.file)
                            readonly property bool active: have && Config.voice.modelPath === "" && Config.voice.model === modelData.id
                            readonly property bool loading: VoiceService.downloading === modelData.id

                            width: parent.width
                            height: 44
                            radius: active ? 22 : 14
                            color: active ? Colors.md3.primary_container : tileMa.containsMouse ? Config.dim(Colors.md3.surface_container_highest) : Config.dim(Colors.md3.surface_container_high)

                            Behavior on radius {
                                NumberAnimation {
                                    duration: 350
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 2.2
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            MouseArea {
                                id: tileMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: tile.active || tile.loading ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (tile.have)
                                        VoiceService.selectModel(tile.modelData.id);
                                    else if (!tile.loading)
                                        VoiceService.downloadModel(tile.modelData.id);
                                }
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 14
                                    rightMargin: 6
                                }
                                spacing: 10

                                Text {
                                    text: tile.modelData.name
                                    font.family: Config.fontFamily
                                    font.pixelSize: 13
                                    font.weight: tile.active ? Font.Medium : Font.Normal
                                    color: tile.active ? Colors.md3.on_primary_container : Colors.md3.on_surface
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Localization.t("voicePage.params").arg(tile.modelData.params) + " · " + tile.modelData.size + " · " + Localization.t("voicePage.hint_" + tile.modelData.id)
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: tile.active ? Colors.md3.on_primary_container : Colors.md3.outline
                                    opacity: tile.active ? 0.8 : 1
                                    elide: Text.ElideRight
                                }

                                WavyProgress {
                                    visible: tile.loading
                                    Layout.preferredWidth: 90
                                    value: VoiceService.downloadProgress
                                }

                                Text {
                                    visible: tile.loading
                                    text: Math.round(VoiceService.downloadProgress * 100) + "%"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Colors.md3.on_surface_variant
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 30
                                }

                                MaterialIcon {
                                    visible: tile.active
                                    name: "check"
                                    iconSize: 18
                                    color: Colors.md3.on_primary_container
                                    transitionType: "none"
                                    Layout.rightMargin: 8
                                }

                                Rectangle {
                                    readonly property bool isButton: tile.loading || tile.have
                                    visible: !tile.active
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: !isButton ? "transparent" : iconMa.containsMouse ? Colors.md3.surface_bright : Config.dim(Colors.md3.surface_container_highest)

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: tile.loading ? "close" : tile.have ? "delete" : "arrow-downward"
                                        iconSize: 17
                                        color: parent.isButton ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                                        transitionType: "none"
                                    }

                                    MouseArea {
                                        id: iconMa
                                        anchors.fill: parent
                                        enabled: parent.isButton
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (tile.loading)
                                                VoiceService.cancelDownload();
                                            else
                                                VoiceService.deleteModel(tile.modelData.id);
                                        }
                                    }

                                    Tooltip {
                                        text: tile.loading ? Localization.t("systemPage.tooltip_cancel_download") : tile.have ? Localization.t("systemPage.tooltip_delete_model") : Localization.t("systemPage.tooltip_download_model")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SettingSwitch {
                label: Localization.t("voicePage.gpu")
                sublabel: Localization.t("voicePage.gpu_sub")
                checked: Config.voice.gpu
                onToggled: v => pageRoot.setVoice("gpu", v)
            }

            SettingChips {
                label: Localization.t("voicePage.output")
                sublabel: Localization.t(VoiceService.hasWtype ? "voicePage.output_sub" : "voicePage.output_no_wtype")
                enabled: VoiceService.hasWtype
                opacity: enabled ? 1.0 : 0.4
                options: [
                    {
                        label: Localization.t("voicePage.output_type"),
                        value: "type",
                    },
                    {
                        label: Localization.t("voicePage.output_copy"),
                        value: "copy",
                    }
                ]
                currentValue: VoiceService.output
                onSelected: v => pageRoot.setVoice("output", v)
            }

            SettingSelect {
                label: Localization.t("voicePage.language")
                sublabel: Localization.t("voicePage.language_sub")
                options: pageRoot.voiceLanguages
                currentValue: Config.voice.language
                onSelected: v => pageRoot.setVoice("language", v)
            }

            SettingSlider {
                isLast: true
                label: Localization.t("voicePage.unload")
                sublabel: Localization.t("voicePage.unload_sub")
                from: 0
                to: 600
                stepSize: 30
                unit: "s"
                value: Config.voice.unloadSeconds
                onMoved: v => pageRoot.setVoice("unloadSeconds", v)
            }
        }

        SectionCard {
            label: Localization.t("voicePage.advanced")
            Layout.fillWidth: true

            SettingInput {
                label: Localization.t("voicePage.server")
                sublabel: Localization.t("voicePage.server_sub")
                fieldWidth: 220
                value: Config.voice.serverPath
                onCommitted: v => pageRoot.setVoice("serverPath", v.trim())
            }

            SettingInput {
                label: Localization.t("voicePage.custom_model")
                sublabel: Localization.t("voicePage.custom_model_sub")
                fieldWidth: 220
                value: Config.voice.modelPath
                onCommitted: v => pageRoot.setVoice("modelPath", v.trim())
            }

            SettingInput {
                isLast: true
                label: Localization.t("voicePage.port")
                sublabel: Localization.t("voicePage.port_sub")
                fieldWidth: 90
                value: String(Config.voice.port)
                onCommitted: v => {
                    const n = parseInt(v);
                    if (n > 0 && n < 65536)
                        pageRoot.setVoice("port", n);
                }
            }
        }

        SectionCard {
            label: Localization.t("systemPage.fonts")
            Layout.fillWidth: true

            SettingSelect {
                label: Localization.t("systemPage.interface_font")
                sublabel: Localization.t("systemPage.system_default_typeface")
                options: pageRoot.systemFontsModel
                currentValue: Config.fontFamily
                onSelected: v => {
                    if (v && v.trim().length > 0) {
                        Config.update({
                            fontFamily: v.trim()
                        });
                    }
                }
            }

            SettingSelect {
                isLast: true
                label: Localization.t("systemPage.monospace_font")
                sublabel: Localization.t("systemPage.fixed_width_terminal_typeface")
                options: pageRoot.systemFontsModel
                currentValue: Config.fontMonospace
                onSelected: v => {
                    if (v && v.trim().length > 0) {
                        Config.update({
                            fontMonospace: v.trim()
                        });
                    }
                }
            }
        }

        SectionCard {
            label: Localization.t("systemPage.api_keys")
            Layout.fillWidth: true

            SecretInput {
                isLast: true
                label: Localization.t("systemPage.wolfram_alpha")
                sublabel: Localization.t("systemPage.key_for_the_wolfram_launcher")
                secretKey: "wolfram"
            }
        }

        SectionCard {
            label: Localization.t("systemPage.screenshots")
            Layout.fillWidth: true

            SettingSwitch {
                isLast: true
                label: Localization.t("systemPage.instant_capture")
                sublabel: Localization.t("systemPage.instant_capture_sub")
                checked: Config.screencap.instantCapture
                onToggled: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            instantCapture: v
                        })
                    })
            }
        }

        SectionCard {
            label: Localization.t("systemPage.script_paths")
            Layout.fillWidth: true

            SettingInput {
                label: Localization.t("qsTileService.screenshot")
                sublabel: Localization.t("systemPage.capture_script")
                value: Config.screencap.screenshotPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            screenshotPath: v
                        })
                    })
            }

            SettingInput {
                label: Localization.t("keybindsPage.screen_record")
                sublabel: Localization.t("systemPage.recording_script")
                value: Config.screencap.recordPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            recordPath: v
                        })
                    })
            }

            SettingInput {
                label: Localization.t("systemPage.cts")
                sublabel: Localization.t("systemPage.circle_to_search")
                value: Config.screencap.ctsPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ctsPath: v
                        })
                    })
            }

            SettingInput {
                label: Localization.t("barPage.ocr")
                sublabel: Localization.t("systemPage.text_recognition")
                value: Config.screencap.ocrPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ocrPath: v
                        })
                    })
            }

            SettingInput {
                label: Localization.t("systemPage.songrec")
                sublabel: Localization.t("systemPage.song_recognition")
                value: Config.screencap.songrecPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            songrecPath: v
                        })
                    })
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component HardwareCard: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 72
        radius: 12
        color: (Config.dim(Colors.md3.surface_container))

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.leftMargin: 16
            spacing: 4

            Text {
                text: parent.parent.labelText
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 1.1
                color: Colors.md3.outline
            }
            Text {
                text: parent.parent.valueText
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Colors.md3.on_surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        required property string labelText
        required property string valueText
    }
}
