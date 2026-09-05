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

    readonly property var groups: {
        const byPage = ({});
        const order = [];
        for (const entry of results) {
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
            checked: entry ? SettingsRegistry.readValue(entry) : false
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
            value: entry ? SettingsRegistry.readValue(entry) : 0
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
            currentValue: entry ? SettingsRegistry.readValue(entry) : null
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
            currentValue: entry ? SettingsRegistry.readValue(entry) : null
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
            value: entry ? (SettingsRegistry.readValue(entry) ?? "") : ""
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
            value: entry ? (SettingsRegistry.readValue(entry) ?? "") : ""
            onCommitted: v => SettingsRegistry.apply(entry.path, v)
        }
    }

    Component {
        id: timeRowComp
        TimeInput {
            property var entry
            label: entry ? entry.label : ""
            sublabel: entry ? resultsRoot.rowSublabel(entry) : ""
            value: entry ? (SettingsRegistry.readValue(entry) ?? "00:00") : "00:00"
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
        if (entry && entry.source)
            return entry.source.options ?? [];
        return entry?.meta.options ?? [];
    }
}
