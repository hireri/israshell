import QtQuick
import Quickshell.Widgets
import QtQuick.Controls.Basic
import qs.style
import qs.icons

Control {
    id: combo

    property var options: []
    property var currentValue: null
    signal selected(var value)
    signal aboutToOpen()

    implicitWidth: combo.optimalWidth
    implicitHeight: 36

    focus: true

    property var filteredOptions: combo.options
    property int activeIndex: -1
    property string selectedLabel: ""

    readonly property var selectedOption: combo.options.find(function (o) {
        return o.value === combo.currentValue;
    }) ?? null
    readonly property bool hasIcons: combo.options.some(function (o) {
        return o.icon !== undefined && o.icon !== null;
    })

    property int optimalWidth: 140

    TextMetrics {
        id: textMetrics
        font.family: Config.fontFamily
        font.pixelSize: 12
    }

    function updateOptimalWidth() {
        var minWidth = 140;
        var maxLimit = hasIcons ? 300 : 260;

        if (!combo.options || combo.options.length === 0) {
            optimalWidth = minWidth;
            return;
        }

        var iconAllowance = hasIcons ? 44 : 0;
        var calculatedWidth = minWidth;
        for (var i = 0; i < combo.options.length; ++i) {
            var label = combo.options[i].label;

            if (label.length >= 25) {
                optimalWidth = maxLimit;
                return;
            }

            textMetrics.text = label;
            var itemWidth = textMetrics.width + 46 + iconAllowance;
            if (itemWidth > calculatedWidth) {
                calculatedWidth = itemWidth;
            }
        }

        optimalWidth = Math.min(calculatedWidth, maxLimit);
    }

    onFilteredOptionsChanged: {
        if (popupMenu.visible) {
            popupMenu.reposition();
        }
    }

    onCurrentValueChanged: {
        var selectedOpt = combo.options.find(function (o) {
            return o.value === combo.currentValue;
        });
        combo.selectedLabel = selectedOpt ? selectedOpt.label : "";
        textField.text = combo.selectedLabel;
    }

    onOptionsChanged: {
        combo.filteredOptions = combo.options;
        var selectedOpt = combo.options.find(function (o) {
            return o.value === combo.currentValue;
        });
        combo.selectedLabel = selectedOpt ? selectedOpt.label : "";
        textField.text = combo.selectedLabel;

        combo.updateOptimalWidth();
    }

    Component.onCompleted: {
        var selectedOpt = combo.options.find(function (o) {
            return o.value === combo.currentValue;
        });
        selectedLabel = selectedOpt ? selectedOpt.label : "";
        textField.text = selectedLabel;

        combo.updateOptimalWidth();
    }

    function filterOptions(query) {
        if (!query) {
            filteredOptions = combo.options;
        } else {
            var q = query.toLowerCase().trim();
            filteredOptions = combo.options.filter(function (o) {
                return o.label.toLowerCase().indexOf(q) !== -1;
            });
        }
        activeIndex = filteredOptions.length > 0 ? 0 : -1;
    }

    function selectOption(opt) {
        selectedLabel = opt.label;
        textField.text = opt.label;
        combo.selected(opt.value);
        combo.filteredOptions = combo.options;
        popupMenu.close();
        combo.forceActiveFocus();
    }

    function revertOrApply() {
        var typed = textField.text.trim().toLowerCase();
        var exactMatch = combo.options.find(function (o) {
            return o.label.toLowerCase() === typed;
        });

        if (exactMatch) {
            selectOption(exactMatch);
        } else {
            textField.text = selectedLabel;
            combo.filteredOptions = combo.options;
        }
    }

    function highlightMatch(label, query) {
        if (!query)
            return escapeHtml(label);
        var idx = label.toLowerCase().indexOf(query.toLowerCase());
        if (idx === -1)
            return escapeHtml(label);

        var part1 = label.slice(0, idx);
        var part2 = label.slice(idx, idx + query.length);
        var part3 = label.slice(idx + query.length);

        return escapeHtml(part1) + "<b><font color='" + Colors.md3.primary + "'>" + escapeHtml(part2) + "</font></b>" + escapeHtml(part3);
    }

    function escapeHtml(str) {
        return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
    }

    Loader {
        id: selectedIconLoader
        z: 1
        active: combo.selectedOption !== null && combo.selectedOption.icon !== undefined && combo.selectedOption.icon !== null
        sourceComponent: active ? combo.selectedOption.icon : null
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        onLoaded: {
            if (item && item.hasOwnProperty("modelData"))
                item.modelData = Qt.binding(function () {
                    return combo.selectedOption;
                });
        }
    }

    contentItem: TextField {
        id: textField
        leftPadding: selectedIconLoader.active ? (selectedIconLoader.width + selectedIconLoader.anchors.leftMargin + 8) : 12
        rightPadding: 30
        text: combo.selectedLabel
        font.family: Config.fontFamily
        font.pixelSize: 12
        color: Colors.md3.on_surface
        verticalAlignment: Text.AlignVCenter
        background: Item {}

        onActiveFocusChanged: {
            if (activeFocus) {
                popupMenu.open();
                selectAll();
            } else if (!popupMenu.visible) {
                combo.revertOrApply();
            }
        }

        onTextChanged: {
            if (activeFocus) {
                combo.filterOptions(text);
            }
        }

        Keys.onPressed: event => {
            if (!popupMenu.visible) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                    popupMenu.open();
                    event.accepted = true;
                    return;
                }
            }

            if (event.key === Qt.Key_Down) {
                if (combo.filteredOptions.length > 0) {
                    combo.activeIndex = (combo.activeIndex + 1) % combo.filteredOptions.length;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                if (combo.filteredOptions.length > 0) {
                    combo.activeIndex = (combo.activeIndex - 1 + combo.filteredOptions.length) % combo.filteredOptions.length;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                if (popupMenu.visible && combo.activeIndex >= 0 && combo.activeIndex < combo.filteredOptions.length) {
                    combo.selectOption(combo.filteredOptions[combo.activeIndex]);
                } else {
                    combo.revertOrApply();
                    combo.forceActiveFocus();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                combo.revertOrApply();
                popupMenu.close();
                combo.forceActiveFocus();
                event.accepted = true;
            }
        }
    }

    background: Rectangle {
        radius: 8
        color: (Config.dim(Colors.md3.surface_container_high))
        border.width: (textField.activeFocus || popupMenu.visible) ? 2 : 1
        border.color: (textField.activeFocus || popupMenu.visible) ? Colors.md3.primary : Colors.md3.surface_variant
        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                if (textField.activeFocus) {
                    popupMenu.close();
                    combo.forceActiveFocus();
                } else {
                    textField.forceActiveFocus();
                }
            }
        }
    }

    MaterialIcon {
        id: indicatorIcon
        name: "keyboard-arrow-down"
        iconSize: 14
        color: Colors.md3.outline
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        rotation: popupMenu.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (popupMenu.visible) {
                    popupMenu.close();
                    combo.forceActiveFocus();
                } else {
                    textField.forceActiveFocus();
                    popupMenu.open();
                }
            }
        }
    }

    Popup {
        id: popupMenu
        padding: 0

        y: combo.height + 4

        width: combo.optimalWidth

        function reposition() {
            var rootItem = combo.parent;
            while (rootItem && rootItem.parent) {
                rootItem = rootItem.parent;
            }
            if (!rootItem)
                return;

            var globalPos = combo.mapToItem(rootItem, 0, 0);
            var spaceBelow = rootItem.height - (globalPos.y + combo.height);
            var spaceAbove = globalPos.y;

            var itemHeight = 36;
            var maxDropdownHeight = 280;
            var calculatedHeight = combo.filteredOptions.length === 0 ? 40 : (combo.filteredOptions.length * itemHeight);

            var popupHeight = Math.min(calculatedHeight, maxDropdownHeight);

            if (spaceBelow < popupHeight && spaceAbove > spaceBelow) {
                y = -popupHeight - 4;
            } else {
                y = combo.height + 4;
            }
        }

        onAboutToShow: {
            combo.aboutToOpen();
            reposition();
        }

        onClosed: {
            combo.revertOrApply();
            combo.forceActiveFocus();
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "y"
                from: popupMenu.y < 0 ? (popupMenu.y + 4) : (popupMenu.y - 4)
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 100
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "y"
                to: popupMenu.y < 0 ? (popupMenu.y + 4) : (popupMenu.y - 4)
                duration: 100
                easing.type: Easing.InCubic
            }
        }

        background: Item {}

        contentItem: ClippingRectangle {
            implicitHeight: {
                var calculatedHeight = combo.filteredOptions.length === 0 ? 40 : (combo.filteredOptions.length * 36);
                return Math.min(calculatedHeight, 280);
            }
            color: Colors.md3.surface_container_high
            radius: 8
            border.width: 1
            border.color: Colors.md3.surface_variant

            ListView {
                id: listView
                anchors.fill: parent
                model: combo.filteredOptions
                clip: true
                cacheBuffer: 100
                visible: combo.filteredOptions.length > 0

                property bool isScrolling: false
                Timer {
                    id: scrollResetTimer
                    interval: 100
                    onTriggered: listView.isScrolling = false
                }
                onContentYChanged: {
                    listView.isScrolling = true;
                    scrollResetTimer.restart();
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Connections {
                    target: combo
                    function onActiveIndexChanged() {
                        if (combo.activeIndex >= 0 && popupMenu.visible) {
                            listView.positionViewAtIndex(combo.activeIndex, ListView.Contain);
                        }
                    }
                }

                delegate: ItemDelegate {
                    id: delegateItem
                    width: popupMenu.width
                    height: 36

                    required property var modelData
                    required property int index

                    property bool isSelected: modelData.value === combo.currentValue
                    property bool isActive: index === combo.activeIndex

                    hoverEnabled: true
                    onHoveredChanged: {
                        if (hovered && !listView.isScrolling) {
                            combo.activeIndex = index;
                        }
                    }

                    onClicked: {
                        combo.selectOption(modelData);
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        readonly property bool hasIcon: delegateItem.modelData.icon !== undefined && delegateItem.modelData.icon !== null

                        Loader {
                            id: optionIconLoader
                            active: parent.hasIcon
                            sourceComponent: active ? delegateItem.modelData.icon : null
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            onLoaded: {
                                if (item && item.hasOwnProperty("modelData"))
                                    item.modelData = delegateItem.modelData;
                            }
                        }

                        Text {
                            id: labelText
                            text: combo.highlightMatch(delegateItem.modelData.label, textField.text)
                            textFormat: Text.StyledText
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: delegateItem.isSelected ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                            elide: Text.ElideRight
                            anchors.left: parent.hasIcon ? optionIconLoader.right : parent.left
                            anchors.leftMargin: parent.hasIcon ? 6 : 12
                            anchors.right: checkIcon.visible ? checkIcon.left : parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MaterialIcon {
                            id: checkIcon
                            name: "check"
                            iconSize: 16
                            color: Colors.md3.primary
                            visible: delegateItem.isSelected
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    background: Rectangle {
                        color: delegateItem.isSelected ? Colors.md3.secondary_container : (delegateItem.isActive ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }

            Text {
                text: Localization.t("settingSelect.no_matching_options")
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.on_surface_variant
                anchors.centerIn: parent
                visible: combo.filteredOptions.length === 0
            }
        }
    }
}
