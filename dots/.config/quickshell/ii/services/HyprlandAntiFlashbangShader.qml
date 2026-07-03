pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool enabled: false
    readonly property bool weak: false

    signal enabledChanged()
    signal weakChanged()

    function cycle() {}
    function enable() {}
    function disable() {}
}
