pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var _fieldsByLayout: ({
        vertical: {
            hourSize: { min: 40, max: 200, resizable: true },
            minuteSize: { min: 40, max: 200, resizable: true },
            dateSize: { min: 10, max: 60, resizable: true },
            timeSpacing: { min: -100, max: 40, resizable: false },
            dateSpacing: { min: -60, max: 40, resizable: false }
        },
        horizontal: {
            hourSize: { min: 40, max: 200, resizable: true },
            dateSize: { min: 10, max: 60, resizable: true },
            dateSpacing: { min: -60, max: 40, resizable: false }
        },
        word: {
            hourSize: { min: 20, max: 120, resizable: true },
            dateSize: { min: 10, max: 60, resizable: true },
            wordSpacing: { min: -40, max: 40, resizable: false },
            dateSpacing: { min: -60, max: 40, resizable: false }
        },
        analog: {
            analogSize: { min: 80, max: 500, resizable: true },
            dateSize: { min: 10, max: 60, resizable: true },
            outlineWidth: { min: 0, max: 10, resizable: false }
        }
    })

    readonly property var _scaledFields: ({
        hourSize: { min: 20, max: 200, def: 100 },
        minuteSize: { min: 40, max: 200, def: 100 },
        dateSize: { min: 10, max: 60, def: 25 },
        analogSize: { min: 80, max: 500, def: 200 },
        timeSpacing: { min: -100, max: 40, def: -30 },
        dateSpacing: { min: -60, max: 40, def: -5 },
        wordSpacing: { min: -40, max: 40, def: -6 },
        outlineWidth: { min: 0, max: 10, def: 2 }
    })

    function scaledFields() {
        return Object.keys(root._scaledFields);
    }

    function scaledBoundsFor(field) {
        const entry = root._scaledFields[field];
        return entry ? { min: entry.min, max: entry.max } : null;
    }

    function scaledDefaultFor(field) {
        return root._scaledFields[field]?.def ?? 100;
    }

    function fieldsForLayout(layout) {
        return Object.keys(root._fieldsByLayout[layout] ?? {});
    }

    function resizableFieldsForLayout(layout) {
        const fields = root._fieldsByLayout[layout] ?? {};
        return Object.keys(fields).filter(key => fields[key].resizable);
    }

    function boundsFor(layout, field) {
        const entry = root._fieldsByLayout[layout]?.[field];
        return entry ? { min: entry.min, max: entry.max } : null;
    }
}
