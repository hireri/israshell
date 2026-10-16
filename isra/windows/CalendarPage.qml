pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.icons
import qs.services
import qs.windows.components
import "../services/holidays.js" as Holidays

PageBase {
    id: page
    pageId: "calendar"
    title: Localization.t("settingsWindow.calendar")
    subtitle: Localization.t("calendarPage.subtitle")

    readonly property var _intervals: [5, 15, 30, 60].map(m => ({
                label: Localization.t("calendarPage.minutes").arg(m),
                value: m
            }))

    readonly property string _syncLabel: CalendarService.syncing ? Localization.t("calendarPage.syncing")
        : CalendarService.syncError !== "" ? Localization.t("calendarPage.sync_failed")
        : CalendarService.lastSync > 0 ? Localization.t("calendarPage.last_synced").arg(page._ago(CalendarService.lastSync))
        : Localization.t("calendarPage.never_synced")

    property var _calIds: []
    readonly property string _calKey: CalendarService.calendars.map(c => c.id).join("|")

    on_CalKeyChanged: page._calIds = CalendarService.calendars.map(c => c.id)
    Component.onCompleted: page._calIds = CalendarService.calendars.map(c => c.id)

    readonly property var _regions: [{ label: Localization.t("calendarPage.holiday_region_auto"), value: "" }].concat(Object.keys(Holidays.regions).map(k => ({ label: Holidays.regions[k].name, value: k })))

    readonly property var _shapes: ["clover4", "arrow", "pill", "softBurst", "diamond", "clamShell", "pentagon"]

    function _shapeFor(s) {
        let h = 0;
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) | 0;
        return page._shapes[Math.abs(h) % page._shapes.length];
    }

    function _onColor(c) {
        const k = Qt.color(c);
        return 0.2126 * k.r + 0.7152 * k.g + 0.0722 * k.b > 0.55 ? "#1b1b1f" : "#ffffff";
    }

    function _short(p) {
        const h = Quickshell.env("HOME");
        return h !== "" && (p === h || p.indexOf(h + "/") === 0) ? "~" + p.slice(h.length) : p;
    }

    function _ago(ms) {
        const mins = Math.floor((Date.now() - ms) / 60000);
        if (mins < 1)
            return Localization.t("calendarPage.just_now");
        if (mins < 60)
            return Localization.t("calendarPage.minutes_ago").arg(mins);
        return Localization.t("calendarPage.hours_ago").arg(Math.floor(mins / 60));
    }

    function _patch(changes) {
        Config.update({ calendar: Object.assign({}, Config.calendar, changes) });
    }

    function _addRoot(path) {
        const v = path.trim();
        if (v === "" || Config.calendar.roots.indexOf(v) !== -1)
            return;
        page._patch({ roots: Config.calendar.roots.concat([v]) });
    }

    function _removeRoot(i) {
        page._patch({ roots: Config.calendar.roots.filter((r, j) => j !== i) });
    }

    SectionCard {
        label: Localization.t("calendarPage.calendars")
        Layout.fillWidth: true

        Repeater {
            model: page._calIds

            SettingRow {
                id: calRow
                required property string modelData
                required property int index
                readonly property var cal: CalendarService.calendars.find(c => c.id === calRow.modelData) ?? ({ id: calRow.modelData, name: "", color: "", hidden: false })
                label: cal.name
                sublabel: cal.readOnly ? Localization.t("calendarPage.holidays_sub").arg(Holidays.regions[CalendarService.holidayRegion]?.name ?? "") : cal.id === CalendarService._personalId ? Localization.t("calendarPage.stored_by_shell") : page._short(cal.id)
                isLast: index === page._calIds.length - 1

                readonly property color tint: cal.color !== "" ? cal.color : Colors.md3.primary

                leading: Item {
                    width: 36
                    height: 36

                    MaterialShape {
                        anchors.centerIn: parent
                        shapeSize: 36
                        name: page._shapeFor(calRow.cal.id)
                        color: calRow.tint
                        immediate: true
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "calendar-month"
                        iconSize: 18
                        color: page._onColor(calRow.tint)
                        transitionType: "none"
                    }
                }

                Md3Switch {
                    checked: !calRow.cal.hidden
                    onToggled: v => CalendarService.setHidden(calRow.cal.id, !v)
                }
            }
        }

        SettingRow {
            label: Localization.t("calendarPage.holiday_region")
            isLast: true

            SelectField {
                anchors.verticalCenter: parent?.verticalCenter
                width: 180
                options: page._regions
                currentValue: Config.calendar.holidayRegion
                onSelected: v => page._patch({ holidayRegion: v })
            }
        }

        Text {
            width: parent.width
            visible: CalendarService.calendars.length === 0
            text: Localization.t("calendarPage.no_calendars")
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.outline
            leftPadding: 18
            topPadding: 14
            bottomPadding: 14
        }
    }

    SectionCard {
        label: Localization.t("calendarPage.reminders")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("calendarPage.event_reminders")
            sublabel: Localization.t("calendarPage.event_reminders_sub")
            checked: Config.calendar.reminders !== false
            onToggled: v => page._patch({ reminders: v })
        }

        SettingRow {
            isLast: true
            label: Localization.t("calendarPage.test_reminder")
            sublabel: Localization.t("calendarPage.test_reminder_sub")

            ActionButton {
                anchors.verticalCenter: parent?.verticalCenter
                icon: "notifications"
                label: Localization.t("calendarPage.send_test")
                onClicked: CalendarReminders.test()
            }
        }
    }

    SectionCard {
        label: Localization.t("calendarPage.sources")
        Layout.fillWidth: true

        SettingRow {
            label: Localization.t("calendarPage.shell_folder")
            sublabel: page._short(CalendarService.dir)
        }

        Repeater {
            model: Config.calendar.roots

            SettingRow {
                id: rootRow
                required property var modelData
                required property int index
                label: page._short(String(modelData))

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: Config.dim(Colors.md3.surface_container_high)

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "close"
                        iconSize: 16
                        color: Colors.md3.on_surface
                        transitionType: "none"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page._removeRoot(rootRow.index)
                    }
                }
            }
        }

        SettingRow {
            label: Localization.t("calendarPage.add_folder")
            isLast: true

            TextInputField {
                id: addField
                implicitWidth: 180
                implicitHeight: 36
                anchors.verticalCenter: parent?.verticalCenter
                placeholder: "~/.calendars"
                onCommitted: v => {
                    page._addRoot(v);
                    addField.clear();
                }
            }
        }

        Text {
            width: parent.width
            text: Localization.t("calendarPage.sources_help")
            wrapMode: Text.WordWrap
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Colors.md3.outline
            leftPadding: 18
            rightPadding: 18
            topPadding: 4
            bottomPadding: 14
        }
    }

    SectionCard {
        label: Localization.t("calendarPage.sync")
        Layout.fillWidth: true

        SettingRow {
            label: CalendarService.syncAvailable ? page._syncLabel : Localization.t("calendarPage.sync_status")
            sublabel: CalendarService.syncAvailable ? "" : Localization.t("calendarPage.sync_unavailable")

            Text {
                anchors.verticalCenter: parent?.verticalCenter
                visible: CalendarService.syncAvailable && CalendarService.syncError !== "" && !CalendarService.syncing
                width: Math.min(implicitWidth, 200)
                text: CalendarService.syncError
                elide: Text.ElideRight
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.error
            }

            ActionButton {
                anchors.verticalCenter: parent?.verticalCenter
                icon: "restart"
                label: Localization.t("calendarPage.sync_now")
                enabled: CalendarService.syncAvailable && !CalendarService.syncing
                onClicked: CalendarService.sync()
            }
        }

        SettingSwitch {
            label: Localization.t("calendarPage.sync_automatically")
            enabled: CalendarService.syncAvailable
            opacity: CalendarService.syncAvailable ? 1 : 0.6
            checked: Config.calendar.autoSync
            onToggled: v => page._patch({ autoSync: v })
        }

        SettingChips {
            label: Localization.t("calendarPage.interval")
            visible: Config.calendar.autoSync
            isLast: true
            options: page._intervals
            currentValue: Config.calendar.syncMinutes
            onSelected: v => page._patch({ syncMinutes: v })
        }

        Text {
            width: parent.width
            text: Localization.t("calendarPage.sync_help")
            wrapMode: Text.WordWrap
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Colors.md3.outline
            leftPadding: 18
            rightPadding: 18
            topPadding: 4
            bottomPadding: 14
        }
    }
}
