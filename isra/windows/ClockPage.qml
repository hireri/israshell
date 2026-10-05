pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.qmlmodels
import Quickshell.Widgets
import qs.style
import qs.services
import qs.components
import qs.windows.components
import qs.icons
import "../services/clockOptions.js" as ClockOptions

PageBase {
    id: pageRoot
    pageId: "clock"
    title: Localization.t("settingsWindow.desktop_clock")
    subtitle: Localization.t("clockPage.layout_style_and_sizing")

    readonly property string layoutId: Config.clock.layout ?? "vertical"
    readonly property string effectiveFont: (Config.clock.fontFamily ?? "") !== "" ? Config.clock.fontFamily : Config.fontFamily
    readonly property var optionState: Object.assign({}, Config.clock, { fontFamily: pageRoot.effectiveFont })
    readonly property var manualPosOpt: ClockOptions.option("manualPos")
    readonly property var mainColor: ClockOptions.option("colorRole")
    readonly property var accentColor: ClockOptions.option("subColorRole")
    readonly property string activePreset: ClockOptions.activePreset(Config.clock)

    readonly property var systemFontsModel: {
        const families = Qt.fontFamilies().filter((item, pos, self) => self.indexOf(item) === pos);
        families.sort((a, b) => a.localeCompare(b));
        return families.map(family => ({ label: family, value: family }));
    }

    property var previewTime: new Date()
    Timer {
        interval: 1000
        running: pageRoot.active
        repeat: true
        onTriggered: pageRoot.previewTime = new Date()
    }

    function updateClock(changes) {
        pageRoot.undoSnapshot = null;
        Config.update({
            clock: Object.assign({}, Config.clock, changes)
        });
    }

    property var undoSnapshot: null
    property string undoText: ""

    function applyWithUndo(text, changes) {
        const before = Object.assign({}, Config.clock);
        pageRoot.updateClock(changes);
        pageRoot.undoText = text;
        pageRoot.undoSnapshot = before;
        undoTimer.restart();
    }

    function undo() {
        if (pageRoot.undoSnapshot !== null)
            Config.update({ clock: pageRoot.undoSnapshot });
        pageRoot.undoSnapshot = null;
    }

    Timer {
        id: undoTimer
        interval: 8000
        onTriggered: pageRoot.undoSnapshot = null
    }

    function lt(key) {
        return Localization.t(key);
    }

    function isShown(opt) {
        return ClockOptions.isVisible(opt, pageRoot.layoutId, pageRoot.optionState);
    }

    function value(opt) {
        return Config.clock[opt.key] ?? opt.default;
    }

    function labelOf(opt) {
        return pageRoot.lt(ClockOptions.text(opt, "label", pageRoot.layoutId));
    }

    function subOf(opt) {
        const key = ClockOptions.text(opt, "sub", pageRoot.layoutId);
        return key === "" ? "" : pageRoot.lt(key);
    }

    function isLocked(opt) {
        return ClockOptions.isLocked(opt, pageRoot.optionState);
    }

    function choicesOf(opt) {
        return opt.choices.map(c => ({
            value: c.value,
            label: c.iconOnly ? "" : pageRoot.lt(c.label),
            icon: c.icon ? pageRoot.icons[c.icon] : undefined
        }));
    }

    Component {
        id: alignAutoComp
        MaterialIcon { name: "align-auto"; iconSize: 16; filled: Config.clock.align === "auto" }
    }
    Component {
        id: alignLeftComp
        MaterialIcon { name: "align-left"; iconSize: 16; filled: Config.clock.align === "left" }
    }
    Component {
        id: alignCenterComp
        MaterialIcon { name: "align-center"; iconSize: 16; filled: Config.clock.align === "center" }
    }
    Component {
        id: alignRightComp
        MaterialIcon { name: "align-right"; iconSize: 16; filled: Config.clock.align === "right" }
    }
    component ShapeIcon: MaterialShape { shapeSize: 20; immediate: true }
    component HandIcon: Item {
        id: hand
        property string style
        property color color
        width: 20
        height: 20
        Item {
            anchors.fill: parent
            rotation: 40
            ClockHand { style: hand.style; length: 7; thickness: 5; color: hand.color }
        }
    }

    Component { id: shapeCookie12;  ShapeIcon { name: "cookie12" } }
    Component { id: shapeCookie9;   ShapeIcon { name: "cookie9" } }
    Component { id: shapeSoftBurst; ShapeIcon { name: "softBurst" } }
    Component { id: shapeClover4;   ShapeIcon { name: "clover4" } }
    Component { id: shapeSunny;     ShapeIcon { name: "sunny" } }
    Component { id: shapeCircle;    ShapeIcon { name: "circle" } }
    Component { id: shapeSquare;    ShapeIcon { name: "square" } }
    Component { id: handCapsule;    HandIcon { style: "capsule" } }
    Component { id: handTapered;    HandIcon { style: "tapered" } }
    Component { id: handHollow;     HandIcon { style: "hollow" } }
    Component { id: handNeedle;     HandIcon { style: "needle" } }
    Component { id: handDot;        HandIcon { style: "dot" } }
    Component { id: handTail;       HandIcon { style: "tail" } }

    readonly property var icons: ({
        "align-auto": alignAutoComp,
        "align-left": alignLeftComp,
        "align-center": alignCenterComp,
        "align-right": alignRightComp,
        "shape:cookie12": shapeCookie12,
        "shape:cookie9": shapeCookie9,
        "shape:softBurst": shapeSoftBurst,
        "shape:clover4": shapeClover4,
        "shape:sunny": shapeSunny,
        "shape:circle": shapeCircle,
        "shape:square": shapeSquare,
        "hand:capsule": handCapsule,
        "hand:tapered": handTapered,
        "hand:hollow": handHollow,
        "hand:needle": handNeedle,
        "hand:dot": handDot,
        "hand:tail": handTail
    })

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("overviewPage.desktop_clock")
        subtitle: {
            if (!Config.desktopClock) return Localization.t("clockPage.hidden");

            const layoutNames = {
                "vertical": Localization.t("clockPage.vertical_style"),
                "horizontal": Localization.t("clockPage.horizontal_style"),
                "word": Localization.t("clockPage.word_clock"),
                "analog": Localization.t("clockPage.analog_face")
            };
            const layout = layoutNames[pageRoot.layoutId] ?? Localization.t("clockPage.standard");
            return Localization.t("clockPage.visible_layout").arg(layout);
        }
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: Config.desktopClock ?? false
        onToggled: v => Config.update({ desktopClock: v })
        MaterialIcon { name: "analog-clock"; transitionType: "circle" }
    }

    SectionCard {
        Layout.fillWidth: true
        sectionKey: "position"

        SettingSwitch {
            isLast: true
            settingKey: "manualPos"
            label: pageRoot.labelOf(pageRoot.manualPosOpt)
            sublabel: pageRoot.subOf(pageRoot.manualPosOpt)
            checked: pageRoot.value(pageRoot.manualPosOpt)
            onToggled: v => pageRoot.updateClock({ manualPos: v })
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutInner.implicitHeight + 32
        radius: 20
        color: Config.dim(Colors.md3.surface_container)

        ColumnLayout {
            id: layoutInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    id: layoutButtons
                    model: ClockOptions.layouts()

                    delegate: Rectangle {
                        id: btn
                        required property var modelData
                        required property int index

                        readonly property bool active: pageRoot.layoutId === btn.modelData.id
                        readonly property bool first: btn.index === 0
                        readonly property bool last: btn.index === layoutButtons.count - 1
                        readonly property color contentColor: active
                            ? Colors.md3.on_primary
                            : (mouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 17
                        topLeftRadius: (active || first) ? 17 : 8
                        bottomLeftRadius: (active || first) ? 17 : 8
                        topRightRadius: (active || last) ? 17 : 8
                        bottomRightRadius: (active || last) ? 17 : 8
                        color: active
                            ? Colors.md3.primary
                            : (mouse.containsMouse ? Config.dim(Colors.md3.surface_container_highest) : Config.dim(Colors.md3.surface_container_high))

                        Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on bottomLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on bottomRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: btn.radius
                            topLeftRadius: btn.topLeftRadius
                            bottomLeftRadius: btn.bottomLeftRadius
                            topRightRadius: btn.topRightRadius
                            bottomRightRadius: btn.bottomRightRadius
                            color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            visible: btn.active
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 6

                            MaterialIcon {
                                name: btn.modelData.icon
                                iconSize: 14
                                filled: btn.active
                                color: btn.contentColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: pageRoot.lt(btn.modelData.label)
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: btn.contentColor
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: pageRoot.updateClock({ layout: btn.modelData.id })
                        }
                    }
                }
            }

            ClippingRectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: Config.dim(Colors.md3.surface_container_high)
                radius: 12

                Image {
                    id: wallView
                    source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWallPreview : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                    visible: source !== ""
                    sourceSize: Qt.size(480, 270)
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface, 0.4)
                    visible: wallView.visible
                }

                ClockPreview {
                    anchors.fill: parent
                    cfg: pageRoot.optionState
                    time: pageRoot.previewTime
                    live: pageRoot.active
                    maxScale: pageRoot.layoutId === "analog" ? 0.65 : 0.5
                    shadow: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.15
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColorRoleStrip {
                    label: Localization.t("backgroundPage.main_color")
                    roles: pageRoot.mainColor.roles
                    selected: pageRoot.value(pageRoot.mainColor)
                    onPicked: role => pageRoot.updateClock({ colorRole: role })
                }

                ColorRoleStrip {
                    label: Localization.t("backgroundPage.accent_color")
                    roles: pageRoot.accentColor.roles
                    selected: pageRoot.value(pageRoot.accentColor)
                    fallback: Colors.md3.secondary
                    onPicked: role => pageRoot.updateClock({ subColorRole: role })
                }
            }
        }
    }


    SectionCard {
        Layout.fillWidth: true
        sectionKey: "presets"

        SettingChips {
            label: Localization.t("clockPage.presets")
            sublabel: Localization.t("clockPage.presets_sub")
            options: ClockOptions.presets().map(p => ({ value: p.id, label: pageRoot.lt(p.label) }))
            currentValue: pageRoot.activePreset
            onSelected: v => {
                const hit = ClockOptions.presets().find(p => p.id === v);
                if (hit)
                    pageRoot.applyWithUndo(Localization.t("clockPage.applied_preset").arg(pageRoot.lt(hit.label)), hit.patch);
            }
        }

        SettingActions {
            isLast: true
            label: Localization.t("clockPage.reset_all")
            sublabel: pageRoot.undoSnapshot !== null ? pageRoot.undoText : Localization.t("clockPage.reset_all_sub")

            ActionButton {
                visible: pageRoot.undoSnapshot !== null
                icon: "history"
                label: Localization.t("clockPage.undo")
                onClicked: pageRoot.undo()
            }

            ActionButton {
                icon: "restart"
                label: Localization.t("clockPage.reset_all_button")
                onClicked: pageRoot.applyWithUndo(Localization.t("clockPage.reset_done"), ClockOptions.defaults())
            }
        }
    }

    Repeater {
        model: ClockOptions.groups()

        delegate: SectionCard {
            id: card
            required property var modelData

            Layout.fillWidth: true
            sectionKey: card.modelData.id
            label: pageRoot.lt(card.modelData.label)
            visible: ClockOptions.groupVisible(card.modelData, pageRoot.layoutId, pageRoot.optionState)

            Repeater {
                model: card.modelData.options

                delegate: DelegateChooser {
                    role: "kind"

                    DelegateChoice {
                        roleValue: "switch"
                        SettingSwitch {
                            required property var modelData
                            settingKey: modelData.key
                            visible: pageRoot.isShown(modelData)
                            enabled: !pageRoot.isLocked(modelData)
                            opacity: enabled ? 1 : 0.6
                            label: pageRoot.labelOf(modelData)
                            sublabel: pageRoot.subOf(modelData)
                            checked: pageRoot.value(modelData)
                            onToggled: v => pageRoot.updateClock({ [modelData.key]: v })
                        }
                    }

                    DelegateChoice {
                        roleValue: "slider"
                        SettingSlider {
                            required property var modelData
                            readonly property var span: ClockOptions.range(modelData, pageRoot.layoutId)
                            readonly property real factor: modelData.display ?? 1

                            settingKey: modelData.key
                            visible: pageRoot.isShown(modelData)
                            enabled: !pageRoot.isLocked(modelData)
                            opacity: enabled ? 1 : 0.6
                            label: pageRoot.labelOf(modelData)
                            sublabel: pageRoot.subOf(modelData)
                            from: span.min
                            to: span.max
                            stepSize: span.step
                            unit: span.unit ?? ""
                            value: Math.round(pageRoot.value(modelData) * factor)
                            onMoved: v => pageRoot.updateClock({ [modelData.key]: v / factor })
                        }
                    }

                    DelegateChoice {
                        roleValue: "chips"
                        SettingChips {
                            required property var modelData
                            settingKey: modelData.key
                            visible: pageRoot.isShown(modelData)
                            enabled: !pageRoot.isLocked(modelData)
                            opacity: enabled ? 1 : 0.6
                            label: pageRoot.labelOf(modelData)
                            sublabel: pageRoot.subOf(modelData)
                            options: pageRoot.choicesOf(modelData)
                            currentValue: pageRoot.value(modelData)
                            onSelected: v => pageRoot.updateClock({ [modelData.key]: v })
                        }
                    }

                    DelegateChoice {
                        roleValue: "select"
                        SettingSelect {
                            required property var modelData
                            settingKey: modelData.key
                            visible: pageRoot.isShown(modelData)
                            enabled: !pageRoot.isLocked(modelData)
                            opacity: enabled ? 1 : 0.6
                            label: pageRoot.labelOf(modelData)
                            sublabel: pageRoot.subOf(modelData)
                            options: pageRoot.choicesOf(modelData)
                            currentValue: pageRoot.value(modelData)
                            onSelected: v => pageRoot.updateClock({ [modelData.key]: v })
                        }
                    }

                    DelegateChoice {
                        roleValue: "font"
                        SettingSelect {
                            required property var modelData
                            settingKey: modelData.key
                            visible: pageRoot.isShown(modelData)
                            enabled: !pageRoot.isLocked(modelData)
                            opacity: enabled ? 1 : 0.6
                            label: pageRoot.labelOf(modelData)
                            sublabel: pageRoot.subOf(modelData)
                            options: pageRoot.systemFontsModel
                            currentValue: pageRoot.value(modelData)
                            onSelected: v => {
                                if (v && v.trim().length > 0)
                                    pageRoot.updateClock({ [modelData.key]: v.trim() });
                            }
                        }
                    }
                }
            }
        }
    }
}
