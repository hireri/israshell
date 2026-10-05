pragma Singleton
import Quickshell
import QtQuick
import "clockOptions.js" as ClockOptions

Singleton {
    id: root

    function scaledFields() {
        return ClockOptions.scaledFields();
    }

    function scaledBoundsFor(field) {
        return ClockOptions.scaledBoundsFor(field);
    }

    function scaledDefaultFor(field) {
        return ClockOptions.scaledDefaultFor(field);
    }

    function fieldsForLayout(layout) {
        return ClockOptions.fieldsForLayout(layout);
    }

    function resizableFieldsForLayout(layout) {
        return ClockOptions.resizableFieldsForLayout(layout);
    }

    function boundsFor(layout, field) {
        return ClockOptions.boundsFor(layout, field);
    }
}
