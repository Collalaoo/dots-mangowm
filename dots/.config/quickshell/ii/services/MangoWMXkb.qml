pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

Singleton {
    id: root

    property string currentLayout: "us"
    property var layouts: ["us"]

    signal layoutChanged(string layout)

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.fetch()
    }

    function fetch() {
        Process.exec("mmsg", ["-g", "-k"], function(result) {
            if (result.exitCode != 0) return
            try {
                var line = result.stdout.trim();
                var parts = line.split(/\s+/);
                if (parts.length >= 3 && parts[1] === "kb_layout") {
                    var layout = parts.slice(2).join(" ");
                    if (layout != root.currentLayout) {
                        root.currentLayout = layout;
                        root.layouts = [layout];
                        root.layoutChanged(layout);
                    }
                }
            } catch (e) {}
        })
    }

    Component.onCompleted: fetch()
}
