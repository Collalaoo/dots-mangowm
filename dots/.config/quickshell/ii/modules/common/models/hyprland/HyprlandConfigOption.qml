pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell.Io
import qs.services
import "../"

NestableObject {
    id: root

    required property string key
    property alias fetching: fetchProc.running
    property bool set
    property var value

    readonly property string mangoConfig: Directories.homePath + "/.config/mango/General.conf"

    Component.onCompleted: fetch()

    Connections {
        target: HyprlandConfig
        function onReloaded() {
            root.fetch();
        }
    }

    function fetch() {
        fetchProc.command = ["grep", "^" + root.key.replace(/\./g, "\\.") + "=", root.mangoConfig];
        fetchProc.running = true;
    }

    function setValue(newValue) {
        HyprlandConfig.set(root.key, newValue)
    }

    function reset() {
        HyprlandConfig.reset(root.key)
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim();
                if (!line) {
                    root.value = undefined;
                    root.set = false;
                    return;
                }
                var eq = line.indexOf("=");
                if (eq >= 0) {
                    var val = line.substring(eq + 1).trim();
                    root.value = val;
                    root.set = true;
                }
            }
        }
    }
}
