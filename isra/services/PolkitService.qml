pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    readonly property bool active: agent.isActive
    readonly property var flow: agent.flow

    property string draft: ""
    property bool wrong: false
    signal failed

    readonly property bool busy: !(root.flow?.isResponseRequired ?? false)

    property string message: ""
    property string supplementary: ""
    property bool supplementaryIsError: false
    readonly property bool lockedOut: /left to unlock/i.test(root.supplementary)
    property var idNames: []
    property int selIdx: 0

    function _idNames() {
        const out = [];
        for (const i of root.flow.identities)
            out.push(i.displayName);
        return out;
    }

    function _selIdx() {
        const l = root.flow.identities;
        for (let i = 0; i < l.length; i++)
            if (l[i] === root.flow.selectedIdentity)
                return i;
        return 0;
    }

    function submit(text) {
        if (!busy && text.length > 0)
            root.flow.submit(text);
    }

    function cancel() {
        root.flow?.cancelAuthenticationRequest();
    }

    function selectIdentity(i) {
        root.flow.selectedIdentity = root.flow.identities[i];
    }

    Binding { target: root; property: "message"; value: root.flow?.message ?? ""; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "supplementary"; value: root.flow?.supplementaryMessage ?? ""; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "supplementaryIsError"; value: root.flow?.supplementaryIsError ?? false; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "idNames"; value: root.flow ? root._idNames() : []; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "selIdx"; value: root.flow ? root._selIdx() : 0; when: root.flow !== null; restoreMode: Binding.RestoreNone }

    Connections {
        target: agent
        function onFlowChanged() {
            root.draft = "";
            root.wrong = false;
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.draft = "";
            root.wrong = true;
            root.failed();
        }
    }

    PolkitAgent {
        id: agent
    }
}
