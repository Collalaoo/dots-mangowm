pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// mmsg-based MangoWM compositor data provider
// API-compatible subset of Quickshell.Hyprland

Singleton {
    id: root

    property ListModel workspaces: ListModel {}
    property ListModel monitors: ListModel {}
    property ListModel clients: ListModel {}
    property ListModel layers: ListModel {}

    property int _activeWsId: 1
    property string _activeMonitor: ""

    readonly property QtObject activeWorkspace: QtObject {
        readonly property int id: root._activeWsId
        readonly property string monitorName: root._activeMonitor
    }

    function activeMonitor() { return root._activeMonitor }

    signal workspaceChanged(int id)
    signal monitorChanged(string name)
    signal clientChanged(string address)

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    function poll() {
        Process.exec("mmsg", ["-g", "-w"], function(ws) {
            if (ws.exitCode == 0 && ws.stdout) {
                var id = parseInt(ws.stdout.trim())
                if (id != root._activeWsId) {
                    root._activeWsId = id
                    root.workspaceChanged(id)
                }
            }
        })

        Process.exec("mmsg", ["-g", "-m"], function(mon) {
            if (mon.exitCode == 0 && mon.stdout) {
                root._activeMonitor = mon.stdout.trim()
            }
        })

        Process.exec("mmsg", ["-g", "-w", "-j"], function(list) {
            if (list.exitCode != 0) return
            try {
                var arr = JSON.parse(list.stdout)
                workspaces.clear()
                for (var i = 0; i < arr.length; i++) {
                    var w = arr[i]
                    workspaces.append({
                        id: w.id,
                        name: w.name || "Tag " + w.id,
                        monitorName: w.monitor || root._activeMonitor,
                        windows: w.windows || 0
                    })
                }
            } catch (e) {}
        })
    }

    function dispatch(cmd) {
        Process.exec("mmsg", cmd.split(" "), function() {})
    }

    function monitorFor(screen) {
        return monitors.count > 0 ? monitors.get(0) : null
    }

    property QtObject rawEvent: QtObject {
        function connect(cb) {} // stub
    }

    Component.onCompleted: poll()
}
