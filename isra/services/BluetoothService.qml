pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false

    readonly property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property list<var> pairedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected)
    readonly property list<var> allDevices: Bluetooth.devices.values.filter(d => d.paired || d.connected)
    readonly property list<var> newDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected)
    readonly property var firstConnected: Bluetooth.devices.values.find(d => d.connected) ?? null

    property bool discovering: false
    property bool _knr: false

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

    function toggle() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    onBluetoothEnabledChanged: {
        if (!bluetoothEnabled) {
            root.discovering = false;
            root._knr = false;
        }
    }

    function setDiscovering(value) {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter)
            return;
        if (value) {
            adapter.discovering = true;
            root._knr = true;
            root.discovering = true;
        } else {
            if (root._knr)
                adapter.discovering = false;
            root._knr = false;
            root.discovering = false;
        }
    }

    function connectDevice(device) {
        device.connect();
    }
    function disconnectDevice(device) {
        device.disconnect();
    }
    function forgetDevice(device) {
        device.forget();
    }
    function pairDevice(device) {
        device.pair();
    }
}
