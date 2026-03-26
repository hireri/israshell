pragma Singleton

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false

    function toggle() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
