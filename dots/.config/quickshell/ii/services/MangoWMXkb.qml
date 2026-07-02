pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

// Keyboard layout indicator via mmsg
Singleton {
    id: root

    property string currentLayout: "us"
    property var layouts: ["us"]

    signal layoutChanged(string layout)

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.fetch()
    }

    function fetch() {
        Process.exec("mmsg", ["devices", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                var data = JSON.parse(result.stdout)
                if (data.keyboard && data.keyboard.active_layout) {
                    var layout = data.keyboard.active_layout
                    if (layout != root.currentLayout) {
                        root.currentLayout = layout
                        root.layoutChanged(layout)
                    }
                }
            } catch (e) {}
        })
    }

    Component.onCompleted: fetch()
}
