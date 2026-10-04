import QtQuick
import qs.style
import "lockLayout.js" as Layouts

Item {
    id: root

    property bool open: false

    readonly property string current: Layouts.valid(Config.lockscreen.layout)
    readonly property var options: [
        { value: "dock", label: Localization.t("lockSurface.layout_dock"), icon: "chromeos-bar" },
        { value: "corners", label: Localization.t("lockSurface.layout_corners"), icon: "grid-view" },
        { value: "center", label: Localization.t("lockSurface.layout_center"), icon: "recenter" }
    ]

    implicitWidth: 56
    implicitHeight: 56

    Timer {
        interval: 6000
        running: root.open
        onTriggered: root.open = false
    }

    LockButton {
        anchors.fill: parent
        size: 56
        restRadius: 20
        icon: "edit"
        container: Colors.md3.primary_container
        content: Colors.md3.on_primary_container
        onClicked: root.open = !root.open
    }

    LockMenu {
        anchors {
            right: parent.right
            bottom: parent.top
            bottomMargin: 8
        }
        opensUp: true
        open: root.open
        entries: root.options.map(o => ({ label: o.label, icon: o.icon, checked: o.value === root.current }))
        onTriggered: i => {
            Config.update({ lockscreen: Object.assign({}, Config.lockscreen, { layout: root.options[i].value }) });
            root.open = false;
        }
    }
}
