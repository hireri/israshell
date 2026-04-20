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

    readonly property var firstConnected: Bluetooth.devices.values.find(d => d.connected) ?? null

    function toggle() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = !adapter.enabled;
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
