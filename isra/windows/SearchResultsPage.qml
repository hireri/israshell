pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons
import qs.windows.components

PageBase {
    id: resultsRoot

    property string query: ""
    signal openPage(string pageId)

    readonly property var results: SettingsRegistry.search(query)

    Timer {
        id: applyDebounce
        interval: 250
        property string path: ""
        property var value
        onTriggered: SettingsRegistry.apply(path, value)
    }

    property int rev: 0
    readonly property var shown: results.slice(0, 40)

    function val(entry) {
        rev;
        const live = SettingsRegistry.byPath[entry.path];
        if (!live)
            return null;
        return live.source ? SettingsRegistry.readValue(live) : (live.value ?? null);
    }

    onResultsChanged: {
        warmup.interval = 400;
        warmup.restart();
    }

    Timer {
        id: warmup
        interval: 400
        repeat: true
        property var tried: ({})
        onTriggered: {
            interval = 60;
            const e = resultsRoot.shown.find(r => !tried[r.pageId] && SettingsRegistry.byPath[r.path]?.source === null);
            if (!e) {
                stop();
                return;
            }
            tried[e.pageId] = true;
            SettingsRegistry._ensurePage(e.pageId);
            resultsRoot.rev++;
        }
    }

    readonly property var groups: {
        const byPage = ({});
        const order = [];
        for (const entry of shown) {
            if (!byPage[entry.pageId]) {
                const def = SettingsPages.pageDef(entry.pageId);
                byPage[entry.pageId] = {
                    title: def ? SettingsPages.pageTitle(def) : entry.page,
                    entries: []
                };
                order.push(entry.pageId);
            }
            byPage[entry.pageId].entries.push(entry);
        }
        return order.map(id => byPage[id]);
    }

    title: Localization.t("settingsWindow.search_results")
    subtitle: Localization.t("settingsWindow.results_count").arg(results.length)

    component RowLoader: Loader {
        property bool isLast: false
        onIsLastChanged: if (item)
            item.isLast = isLast
        onLoaded: if (item)
            item.isLast = isLast
    }

    SectionCard {
        visible: resultsRoot.groups.length === 0
        label: ""

        SettingRow {
            label: Localization.t("settingsWindow.no_results")
            isLast: true
        }
    }

    Repeater {
        model: resultsRoot.groups

        delegate: SectionCard {
            required property var modelData
            readonly property var group: modelData

            label: group.title
            Layout.fillWidth: true

            Repeater {
                model: group.entries

                delegate: RowLoader {
                    required property var modelData
                    readonly property var entry: modelData

                    width: parent?.width ?? 0
                    sourceComponent: resultsRoot.rowComps[entry.type] ?? plainRowComp

                    onLoaded: item.entry = entry

                }
            }
        }
    }

    Component {
        id: plainRowComp
        Item {
            id: plainWrap

            property var entry
            property bool isLast: false

            width: parent?.width ?? 0
            height: plainRow.implicitHeight

            SettingRow {
                id: plainRow
                anchors.left: parent.left
                anchors.right: parent.right
                isLast: plainWrap.isLast
                label: plainWrap.entry ? plainWrap.entry.label : ""
                sublabel: plainWrap.entry ? (plainWrap.entry.section || plainWrap.entry.sublabel) : ""

                MaterialIcon {
                    anchors.verticalCenter: parent?.verticalCenter
                    name: "chevron-right"
                    iconSize: 16
                    color: Colors.md3.outline
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: resultsRoot.openPage(plainWrap.entry.pageId)
            }
        }
    }

    Component {
        id: switchRowComp
        SettingSwitch {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            checked: entry ? (resultsRoot.val(entry) ?? false) : false
            onToggled: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: sliderRowComp
        SettingSlider {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            from: entry?.meta.from ?? 0
            to: entry?.meta.to ?? 100
            stepSize: entry?.meta.stepSize ?? 1
            unit: entry?.meta.unit ?? ""
            decimals: entry?.meta.decimals ?? 0
            value: entry ? (resultsRoot.val(entry) ?? 0) : 0
            onMoved: v => {
                applyDebounce.path = entry.path;
                applyDebounce.value = v;
                applyDebounce.restart();
            }
        }
    }

    Component {
        id: selectRowComp
        SettingSelect {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            options: resultsRoot.liveOptions(entry)
            currentValue: entry ? resultsRoot.val(entry) : null
            onSelected: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: chipsRowComp
        SettingChips {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            options: resultsRoot.liveOptions(entry)
            currentValue: entry ? resultsRoot.val(entry) : null
            onSelected: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: inputRowComp
        SettingInput {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            placeholder: entry?.meta.placeholder ?? ""
            value: entry ? (resultsRoot.val(entry) ?? "") : ""
            onCommitted: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: textAreaRowComp
        SettingTextArea {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            placeholder: entry?.meta.placeholder ?? ""
            value: entry ? (resultsRoot.val(entry) ?? "") : ""
            onCommitted: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: timeRowComp
        TimeInput {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            value: entry ? (resultsRoot.val(entry) ?? "00:00") : "00:00"
            onCommitted: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    readonly property var rowComps: ({
        "switch": switchRowComp,
        "slider": sliderRowComp,
        "select": selectRowComp,
        "chips": chipsRowComp,
        "input": inputRowComp,
        "textarea": textAreaRowComp,
        "time": timeRowComp
    })

    function rowSublabel(entry) {
        if (entry.section === "")
            return entry.sublabel;
        if (entry.sublabel === "")
            return entry.section;
        return entry.section + " · " + entry.sublabel;
    }

    function liveOptions(entry) {
        const src = entry ? (rev, SettingsRegistry.byPath[entry.path]?.source) : null;
        if (src)
            return src.options ?? [];
        return entry?.meta.options ?? [];
    }
}
