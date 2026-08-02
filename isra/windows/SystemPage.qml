import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.style
import qs.services
import qs.windows.components
import qs.icons

PageBase {
    id: pageRoot
    title: "System"
    subtitle: "About and script paths"

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

    Component.onCompleted: Updater.checkNow()

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
                text: "<b><font color='" + Colors.md3.on_surface + "'>kernel</font></b> " + SystemInfo.kernel + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>session</font></b> " + SystemInfo.session + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>uptime</font></b> " + SystemInfo.uptime
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
                        text: Updater.applying ? "Updating..." : "↑ " + Updater.latestVersion
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
                        text: "GitHub ↗"
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
                labelText: "CPU"
                valueText: SystemInfo.cpu
                topLeftRadius: 16
                topRightRadius: 8
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: "GPU"
                valueText: SystemInfo.gpu
                topLeftRadius: 8
                topRightRadius: 16
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: "Memory"
                valueText: SystemInfo.memory
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 16
                bottomRightRadius: 4
            }
            HardwareCard {
                labelText: "Motherboard"
                valueText: SystemInfo.motherboard
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 4
                bottomRightRadius: 16
            }
        }

        SectionCard {
            label: "Updates"
            Layout.fillWidth: true

            SettingSwitch {
                label: "Check for updates"
                sublabel: "Poll GitHub for new releases hourly"
                checked: Config.checkUpdates
                onToggled: v => Config.update({
                        checkUpdates: v
                    })
            }

            SettingSwitch {
                isLast: true
                label: "Check dependencies"
                sublabel: "Warn about missing packages on startup"
                checked: Config.checkDeps
                onToggled: v => Config.update({
                        checkDeps: v
                    })
            }
        }

        SectionCard {
            label: "Presets"
            Layout.fillWidth: true

            SettingRow {
                label: "Save preset"
                sublabel: "Snapshot your config to ~/.config/israshell"

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: saveLbl.implicitWidth + 24
                    radius: 16
                    color: Colors.md3.primary
                    opacity: ConfigPresetService.busy ? 0.6 : 1.0

                    Text {
                        id: saveLbl
                        anchors.centerIn: parent
                        text: ConfigPresetService.busy ? "Saving..." : "Save preset"
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
                text: "No presets yet"
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
                                text: "Created " + (ConfigPresetService.nowTick, ConfigPresetService.relativeTime(presetRow.modelData.mtime))
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
                                    text: "Apply"
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

                    Rectangle {
                        visible: presetRow.index < presetRepeater.count - 1
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            leftMargin: 18
                            right: parent.right
                            rightMargin: 18
                        }
                        height: 1
                        color: Colors.md3.outline_variant
                        opacity: 0.5
                    }
                }
            }

            Item {
                visible: ConfigPresetService.entries.length > 0
                width: parent?.width ?? 0
                height: 1

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }

            SettingRow {
                label: "Regenerate config"
                sublabel: "Reset every setting to its default, CANNOT be undone."

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: regenLbl.implicitWidth + 24
                    radius: 16
                    color: Colors.md3.error

                    Text {
                        id: regenLbl
                        anchors.centerIn: parent
                        text: "Regenerate"
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
            label: "System Integration"
            Layout.fillWidth: true

            SettingSwitch {
                label: "Start locked"
                sublabel: "Show lockscreen when shell starts"
                checked: Config.startLocked
                onToggled: v => Config.update({ startLocked: v })
            }

            SettingSwitch {
                label: "Use Hyprlock"
                sublabel: "Delegate locking to Hyprlock instead of built in"
                checked: Config.useHyprlock
                onToggled: v => Config.update({ useHyprlock: v })
            }

            SettingChips {
                isLast: true
                label: "Password dot shape"
                sublabel: "Shape of the lockscreen input dots"
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
            label: "LocalSend"
            Layout.fillWidth: true

            SettingSwitch {
                readonly property bool manageLocally: Config.localsend.host === "127.0.0.1" || Config.localsend.host === "localhost"
                label: "Enable"
                sublabel: LocalSendService.reachable ? "Connected to " + Config.localsend.host + ":" + Config.localsend.port : (manageLocally ? "Starts a local LocalSend server on this device" : (Config.localsend.enabled ? "Server not reachable" : "Server not reachable — start it on " + Config.localsend.host + " first"))
                checked: Config.localsend.enabled
                enabled: manageLocally || LocalSendService.reachable || Config.localsend.enabled
                onToggled: v => Config.update({
                        localsend: Object.assign({}, Config.localsend, {
                            enabled: v
                        })
                    })
            }

            SettingInput {
                label: "Device name"
                sublabel: "How this device appears to others"
                value: Config.localsend.alias ?? ""
                fieldWidth: 160
                onCommitted: v => LocalSendService.setAlias(v)
            }

            SettingInput {
                label: "Host"
                sublabel: "127.0.0.1 runs our own server locally; any other address is treated as remote"
                value: Config.localsend.host
                fieldWidth: 160
                onCommitted: v => Config.update({
                        localsend: Object.assign({}, Config.localsend, {
                            host: v
                        })
                    })
            }

            SettingInput {
                label: "Port"
                sublabel: "LocalSend protocol + control API port"
                value: String(Config.localsend.port)
                fieldWidth: 100
                onCommitted: v => {
                    const port = parseInt(v, 10);
                    if (!isNaN(port) && port > 0 && port < 65536) {
                        Config.update({
                            localsend: Object.assign({}, Config.localsend, {
                                port: port
                            })
                        });
                    }
                }
            }

            SettingSwitch {
                isLast: true
                label: "Notify on receive"
                sublabel: "Show a desktop notification for incoming transfers"
                checked: Config.localsend.notifyOnReceive
                onToggled: v => Config.update({
                        localsend: Object.assign({}, Config.localsend, {
                            notifyOnReceive: v
                        })
                    })
            }
        }

        SectionCard {
            label: "Fonts"
            Layout.fillWidth: true

            SettingSelect {
                label: "Interface font"
                sublabel: "System default typeface"
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
                label: "Monospace font"
                sublabel: "Fixed-width terminal typeface"
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
            label: "Script paths"
            Layout.fillWidth: true

            SettingInput {
                label: "Screenshot"
                sublabel: "Capture script"
                value: Config.screencap.screenshotPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            screenshotPath: v
                        })
                    })
            }

            SettingInput {
                label: "Screen record"
                sublabel: "Recording script"
                value: Config.screencap.recordPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            recordPath: v
                        })
                    })
            }

            SettingInput {
                label: "CTS"
                sublabel: "Circle-to-search"
                value: Config.screencap.ctsPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ctsPath: v
                        })
                    })
            }

            SettingInput {
                label: "OCR"
                sublabel: "Text recognition"
                value: Config.screencap.ocrPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ocrPath: v
                        })
                    })
            }

            SettingInput {
                label: "Songrec"
                sublabel: "Song recognition"
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