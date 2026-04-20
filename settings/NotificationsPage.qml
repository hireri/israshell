import QtQuick
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.settings.components

PageBase {
    title: "Notifications"
    subtitle: "DND and timeout"

    HeroCard {
        Layout.fillWidth: true
        title: "Do not disturb"
        subtitle: "Suppress all notification popups"
        iconBg: Colors.md3.secondary_container
        cardColor: Colors.md3.surface_container
        checked: NotificationService.dnd
        onToggled: v => NotificationService.dnd = v
    }

    SectionCard {
        label: "Behaviour"
        Layout.fillWidth: true

        SettingSelect {
            label: "Popup timeout"
            sublabel: "How long popups stay visible"
            iconBg: Colors.md3.secondary_container
            options: [
                {
                    label: "3 seconds",
                    value: 3000
                },
                {
                    label: "5 seconds",
                    value: 5000
                },
                {
                    label: "8 seconds",
                    value: 8000
                },
                {
                    label: "Never",
                    value: 0
                }
            ]
            currentValue: Config.notificationTimeout ?? 5000
            onSelected: v => Config.update({
                    notificationTimeout: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show on all monitors"
            sublabel: "Mirror popups across every screen"
            iconBg: Colors.md3.secondary_container
            checked: Config.notificationsAllMonitors ?? false
            onToggled: v => Config.update({
                    notificationsAllMonitors: v
                })
        }
    }
}
