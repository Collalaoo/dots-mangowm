pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property string focusedMonitorName: ""
    property var layers: ({})

    signal focusedWorkspaceChanged(int id)
    signal workspacesChanged()

    function toplevelsForWorkspace(workspace) {
        return root.windowList.filter(function(win) {
            return win.workspace === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(function(win) {
            return win.workspace === workspace;
        })
    }

    function clientForToplevel(toplevel) {
        if (!toplevel) return null;
        var addr = toplevel.address ?? toplevel.var?.address;
        if (!addr) return null;
        return root.windowByAddress[addr.startsWith("0x") ? addr : "0x" + addr];
    }

    function biggestWindowForWorkspace(workspaceId) {
        var wins = root.windowList.filter(function(w) { return w.workspace == workspaceId });
        return wins.reduce(function(maxWin, win) {
            var maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            var winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    function monitorFor(screen) {
        if (!screen) return null;
        for (var i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === screen.name) return root.monitors[i];
        }
        if (root.monitors.length > 0) return root.monitors[0];
        return null;
    }

    function dispatch(cmd) {
        var parts = cmd.split(/\s+/);
        var args = ["dispatch"].concat(parts);
        Process.exec("mmsg", args, function() {});
    }

    function updateAll() {
        fetchClients.running = true;
        fetchMonitors.running = true;
        fetchWorkspacesList.running = true;
        fetchActiveWs.running = true;
    }

    function _updateFocusedMonitor() {
        for (var i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].focused) {
                root.focusedMonitorName = root.monitors[i].name;
                return;
            }
        }
        if (root.monitors.length > 0)
            root.focusedMonitorName = root.monitors[0].name;
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: updateAll()
    }

    Process {
        id: fetchClients
        command: ["mmsg", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text);
                    root.windowList = data;
                    var byAddr = {};
                    for (var i = 0; i < data.length; ++i) {
                        byAddr[data[i].address] = data[i];
                    }
                    root.windowByAddress = byAddr;
                    root.addresses = data.map(function(w) { return w.address });
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchMonitors
        command: ["mmsg", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                    root._updateFocusedMonitor();
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchWorkspacesList
        command: ["mmsg", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = JSON.parse(text);
                    var filtered = raw.filter(function(ws) { return ws.id >= 1 && ws.id <= 100 });
                    var changed = filtered.length !== root.workspaces.length;
                    root.workspaces = filtered;
                    var byId = {};
                    for (var i = 0; i < filtered.length; ++i) {
                        byId[filtered[i].id] = filtered[i];
                    }
                    root.workspaceById = byId;
                    root.workspaceIds = filtered.map(function(ws) { return ws.id });
                    if (changed) root.workspacesChanged();
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchActiveWs
        command: ["mmsg", "activeworkspace", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text);
                    var prevId = root.activeWorkspace?.id;
                    root.activeWorkspace = data;
                    if (data && data.id !== prevId)
                        root.focusedWorkspaceChanged(data.id);
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchLayers
        command: ["mmsg", "layers", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.layers = JSON.parse(text); } catch (e) {}
            }
        }
    }

    function updateLayers() { fetchLayers.running = true; }

    Component.onCompleted: updateAll()
}
