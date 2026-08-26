pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.style

Singleton {
    id: root

    readonly property bool hasBattery: UPower.displayDevice?.isLaptopBattery ?? false
    readonly property int percentage: hasBattery ? Math.round(UPower.displayDevice.percentage * 100) : 100
    readonly property bool charging: hasBattery && UPower.displayDevice.state === UPowerDeviceState.Charging

    property bool _alerted: false

    onPercentageChanged: _check()
    onChargingChanged: _check()

    function _check() {
        if (!hasBattery || !Config.battery.lowBatteryNotify)
            return;

        if (charging || percentage > Config.battery.lowBatteryThreshold) {
            _alerted = false;
            return;
        }

        if (_alerted)
            return;
        _alerted = true;

        notifyProc.command = ["notify-send", "-u", "critical", "-a", "QuickShell", "-i", "battery-low", Localization.t("systemPage.low_battery"), Localization.t("systemPage.percent_remaining").arg(percentage)];
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
    }
}
