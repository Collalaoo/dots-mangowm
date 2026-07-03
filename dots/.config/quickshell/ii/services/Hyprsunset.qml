pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int gamma: 100
    readonly property bool temperatureActive: false
    readonly property int gammaLowerLimit: 0

    signal gammaChanged()
    signal temperatureActiveChanged()

    function load() {}
    function fetchState() {}
    function toggleTemperature() {}
    function setGamma(v) {}
}
