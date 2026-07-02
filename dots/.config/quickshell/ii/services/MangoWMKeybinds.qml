pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

// Provides keybind list from MangoWM config
Singleton {
    id: root

    property var bindings: []

    signal reloaded()

    function fetch() {
        Process.exec("mmsg", ["binds", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                root.bindings = JSON.parse(result.stdout)
                root.reloaded()
            } catch (e) {}
        })
    }

    Component.onCompleted: fetch()
}
