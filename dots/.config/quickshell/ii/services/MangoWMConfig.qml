pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

// MangoWM config get/set via mmsg
Singleton {
    id: root

    signal reloaded()

    function get(key) {
        var result = Process.execSync("mmsg", ["getoption", key])
        if (result.exitCode == 0) {
            try { return JSON.parse(result.stdout) } catch (e) {}
        }
        return null
    }

    function set(key, value) {
        Process.exec("mmsg", ["setoption", key, value], function() {
            root.reloaded()
        })
    }

    function reset(key) {
        Process.exec("mmsg", ["resetoption", key], function() {
            root.reloaded()
        })
    }

    function reload() {
        Process.exec("mmsg", ["reload"], function() {
            root.reloaded()
        })
    }
}
