pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool discovering: Bluetooth.defaultAdapter?.discovering ?? false

    readonly property var firstConnected: Bluetooth.devices.values.find(d => d.connected) ?? null
    readonly property int connectedCount: Bluetooth.devices.values.filter(d => d.connected).length

    readonly property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    readonly property list<var> pairedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    readonly property list<var> newDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    readonly property list<var> allDevices: [...connectedDevices, ...pairedDevices, ...newDevices]
    readonly property list<var> knownDevices: [...connectedDevices, ...pairedDevices]

    readonly property bool anyDeviceBusy: Bluetooth.devices.values.some(d => isDeviceBusy(d))

    function isDeviceBusy(device) {
        return device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting;
    }

    function toggle() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function setDiscovering(value) {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.discovering = value;
    }

    function connectDevice(device) {
        device.connect();
    }
    function disconnectDevice(device) {
        device.disconnect();
    }
    function pairDevice(device) {
        device.pair();
    }
    function forgetDevice(device) {
        device.forget();
    }

    function sortFunction(a, b) {
        const macRegex = /^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;
        return a.name.localeCompare(b.name);
    }

    function batteryIcon(level) {
        if (level >= 90)
            return "󰁹";
        if (level >= 80)
            return "󰂂";
        if (level >= 70)
            return "󰂁";
        if (level >= 60)
            return "󰂀";
        if (level >= 50)
            return "󰁿";
        if (level >= 40)
            return "󰁾";
        if (level >= 30)
            return "󰁽";
        if (level >= 20)
            return "󰁼";
        if (level >= 10)
            return "󰁻";
        return "󰁺";
    }
}
