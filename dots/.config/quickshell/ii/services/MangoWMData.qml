pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// Replaces Quickshell.Hyprland with mmsg-based IPC for MangoWM
// Provides: workspaces, active workspace, monitors, window list, events

Singleton {
    id: root

    // ── Data models ──────────────────────────────────────────────

    property ListModel workspaces: ListModel {}
    property ListModel monitors: ListModel {}
    property ListModel clients: ListModel {}

    // current workspace id for each monitor
    readonly property QtObject activeWorkspace: QtObject {
        readonly property int id: root._activeWorkspaceId
        readonly property string monitorName: root._activeMonitor
    }

    property int _activeWorkspaceId: 1
    property string _activeMonitor: ""

    // ── Polling / watching ───────────────────────────────────────

    Timer {
        id: pollTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: root.fetchAll()
    }

    function fetchAll() {
        fetchWorkspaces()
        fetchMonitors()
        fetchActiveWorkspace()
        fetchClients()
    }

    function fetchWorkspaces() {
        Process.exec("mmsg", ["workspaces", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                var data = JSON.parse(result.stdout)
                workspaces.clear()
                for (var i = 0; i < data.length; i++) {
                    var ws = data[i]
                    workspaces.append({
                        id: ws.id,
                        name: ws.name || "ws-" + ws.id,
                        monitorName: ws.monitor || "",
                        windows: ws.windows || 0
                    })
                }
            } catch (e) {}
        })
    }

    function fetchMonitors() {
        Process.exec("mmsg", ["monitors", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                var data = JSON.parse(result.stdout)
                monitors.clear()
                for (var i = 0; i < data.length; i++) {
                    var mon = data[i]
                    monitors.append({
                        name: mon.name,
                        width: mon.width,
                        height: mon.height,
                        scale: mon.scale || 1,
                        x: mon.x || 0,
                        y: mon.y || 0
                    })
                }
            } catch (e) {}
        })
    }

    function fetchActiveWorkspace() {
        Process.exec("mmsg", ["active-workspace", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                var data = JSON.parse(result.stdout)
                root._activeWorkspaceId = data.id || 1
                root._activeMonitor = data.monitor || ""
            } catch (e) {}
        })
    }

    function fetchClients() {
        Process.exec("mmsg", ["clients", "-j"], function(result) {
            if (result.exitCode != 0) return
            try {
                var data = JSON.parse(result.stdout)
                clients.clear()
                for (var i = 0; i < data.length; i++) {
                    var c = data[i]
                    clients.append({
                        address: c.address || "",
                        class: c.class || "",
                        title: c.title || "",
                        workspace: c.workspace || 0,
                        monitor: c.monitor || ""
                    })
                }
            } catch (e) {}
        })
    }

    // ── Helper: monitor for a screen ─────────────────────────────
    function monitorFor(screen) {
        if (monitors.count > 0) {
            return monitors.get(0)
        }
        return null
    }

    // ── Dispatch ─────────────────────────────────────────────────
    function dispatch(command) {
        Process.exec("mmsg", command.split(" "), function() {})
    }

    property var rawEvent: QtObject {
        function connect(callback) {
            // stub: no raw event system in MangoWM
        }
    }

    // ── Initial fetch ────────────────────────────────────────────
    Component.onCompleted: fetchAll()
}
