pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

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

    property int tagCount: 9
    property var _tagData: ({})

    signal focusedWorkspaceChanged(int id)
    signal workspacesChanged()

    function toplevelsForWorkspace(workspace) {
        var wsId = (typeof workspace === "object") ? workspace.id : workspace;
        return root.windowList.filter(function(win) {
            return win.workspace?.id === wsId;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        var wsId = (typeof workspace === "object") ? workspace.id : workspace;
        return root.windowList.filter(function(win) {
            return win.workspace?.id === wsId;
        })
    }

    function clientForToplevel(toplevel) {
        if (!toplevel) return null;
        var addr = toplevel.address ?? toplevel.var?.address;
        if (!addr) return null;
        return root.windowByAddress[addr.startsWith("0x") ? addr : "0x" + addr];
    }

    function biggestWindowForWorkspace(workspaceId) {
        var wins = root.windowList.filter(function(w) { return w.workspace?.id == workspaceId });
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
        if (!cmd || cmd.length === 0) return;

        var mcmd = _translateDispatch(cmd);
        if (mcmd) {
            if (mcmd.useSubcommand) {
                Process.exec("mmsg", mcmd.args, function() {});
            } else {
                Process.exec("mmsg", ["-s", "-d"].concat(mcmd.args), function() {});
            }
        }
    }

    function _translateDispatch(cmd) {
        var m = null;

        m = cmd.match(/hl\.dsp\.focus\(\{\s*workspace\s*=\s*["']?(\d+)["']?\s*\}/);
        if (m) return { useSubcommand: true, args: ["tag", m[1]] };

        m = cmd.match(/hl\.dsp\.focus\(\{\s*workspace\s*=\s*["']r[+-](\d+)["']?\s*\}/);
        if (m) {
            var dir = cmd.indexOf("-") > 0 ? "-" + m[1] : "+" + m[1];
            return { useSubcommand: true, args: ["tag", dir] };
        }

        m = cmd.match(/hl\.dsp\.focus\(\{\s*window\s*=\s*"address:([^"]+)"\s*\}/);
        if (m) return { useSubcommand: false, args: ["focuswindow", m[1]] };

        m = cmd.match(/hl\.dsp\.window\.close\(\{\s*window\s*=\s*"address:([^"]+)"\s*\}/);
        if (m) return { useSubcommand: false, args: ["killclient"] };

        m = cmd.match(/hl\.dsp\.window\.move\(\{\s*workspace\s*=\s*(\d+)/);
        if (m) return { useSubcommand: true, args: ["send-to-tag", m[1]] };

        m = cmd.match(/hl\.dsp\.workspace\.toggle_special\(["']special["']\)/);
        if (m) return { useSubcommand: true, args: ["toggle", "scratchpad"] };

        return null;
    }

    function updateAll() {
        fetchTags.running = true;
        fetchMonitors.running = true;
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

    function _rebuildWorkspaces() {
        var byId = {};
        var list = [];
        var ids = [];
        var activeFound = null;

        for (var m = 0; m < root.monitors.length; m++) {
            var mon = root.monitors[m];
            var td = root._tagData[mon.name];
            if (!td || !td.tags) continue;

            var selBitmask = td.sel;
            var activeTagNum = -1;
            if (selBitmask > 0) {
                for (var bits = selBitmask, t = 0; bits; bits >>= 1, t++) {
                    if (bits & 1) { activeTagNum = t + 1; break; }
                }
            }

            for (var i = 0; i < td.tags.length; i++) {
                var tag = td.tags[i];
                var ws = {
                    id: tag.n,
                    name: String(tag.n),
                    monitor: mon.name,
                    occupied: tag.clients > 0,
                    clients: tag.clients,
                    focused: tag.focused === 1,
                    active: tag.state === 1,
                    urgent: tag.state === 2
                };
                byId[tag.n] = ws;
                if (ids.indexOf(tag.n) < 0) ids.push(tag.n);
                if (mon.focused && tag.n === activeTagNum) {
                    activeFound = ws;
                }
            }
        }

        ids.sort(function(a, b) { return a - b; });
        list = ids.map(function(id) { return byId[id]; });

        var prevActiveId = root.activeWorkspace?.id;
        root.workspaceById = byId;
        root.workspaceIds = ids;
        root.workspaces = list;

        if (activeFound) {
            root.activeWorkspace = activeFound;
            if (activeFound.id !== prevActiveId)
                root.focusedWorkspaceChanged(activeFound.id);
        }

        root.workspacesChanged();
    }

    function _rebuildWindowList() {
        var toplevels = ToplevelManager.toplevels.values;
        var list = [];
        var byAddr = {};
        var addrs = [];

        var activeWsId = root.activeWorkspace?.id ?? 1;
        var activeWsObj = { id: activeWsId, name: String(activeWsId) };

        for (var i = 0; i < toplevels.length; i++) {
            var tl = toplevels[i];
            var addr = tl.var?.address;
            if (!addr) continue;
            if (!addr.startsWith("0x")) addr = "0x" + addr;

            var monName = tl.var?.output?.name || root.focusedMonitorName || "";
            var monId = 0;
            for (var mi = 0; mi < root.monitors.length; mi++) {
                if (root.monitors[mi].name === monName) { monId = root.monitors[mi].id; break; }
            }

            var win = {
                address: addr,
                class: tl.appId || "",
                title: tl.title || "",
                workspace: activeWsObj,
                at: [tl.x || 0, tl.y || 0],
                size: [tl.width || 0, tl.height || 0],
                mapped: tl.activated ?? true,
                monitor: monId,
                floating: tl.var?.floating ?? false,
                fullscreen: tl.fullscreen ?? false,
                pinned: false,
                pid: tl.pid ?? 0,
                xwayland: false,
                wayland: { fullscreen: tl.fullscreen ?? false }
            };
            list.push(win);
            byAddr[addr] = win;
            addrs.push(addr);
        }

        root.windowList = list;
        root.windowByAddress = byAddr;
        root.addresses = addrs;
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: updateAll()
    }

    Process {
        id: fetchTags
        command: ["mmsg", "-g", "-t"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var lines = text.split("\n");
                    var currentMon = "";
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (!line) continue;

                        var parts = line.split(/\s+/);
                        if (parts.length < 2) continue;

                        if (parts[0] === "tags" && parts.length >= 4) {
                            var mon = currentMon;
                            if (!root._tagData[mon]) root._tagData[mon] = { tags: [], occ: 0, sel: 0, urg: 0 };
                            root._tagData[mon].occ = parseInt(parts[1]) || 0;
                            root._tagData[mon].sel = parseInt(parts[2]) || 0;
                            root._tagData[mon].urg = parseInt(parts[3]) || 0;
                        } else if (parts[0] === "tag" && parts.length >= 5) {
                            var mon = currentMon;
                            var tagN = parseInt(parts[1]);
                            if (!root._tagData[mon]) root._tagData[mon] = { tags: [], occ: 0, sel: 0, urg: 0 };
                            var tagArr = root._tagData[mon].tags;
                            var tagIdx = -1;
                            for (var t = 0; t < tagArr.length; t++) {
                                if (tagArr[t].n === tagN) { tagIdx = t; break; }
                            }
                            var tagObj = {
                                n: tagN,
                                state: parseInt(parts[2]) || 0,
                                clients: parseInt(parts[3]) || 0,
                                focused: parseInt(parts[4]) || 0
                            };
                            if (tagIdx >= 0) tagArr[tagIdx] = tagObj;
                            else tagArr.push(tagObj);
                        } else if (parts[0] === "clients") {
                        } else {
                            currentMon = parts[0];
                        }
                    }
                    root._rebuildWorkspaces();
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchMonitors
        command: ["mmsg", "-O"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var names = text.trim().split("\n").filter(function(l) {
                        return l.length > 0 && l !== "+" && l !== "-" && !l.match(/^[+-]\s/);
                    });
                    var newMonitors = [];
                    for (var i = 0; i < names.length; i++) {
                        var name = names[i].trim();
                        var existing = null;
                        for (var j = 0; j < root.monitors.length; j++) {
                            if (root.monitors[j].name === name) { existing = root.monitors[j]; break; }
                        }
                        newMonitors.push({
                            id: i,
                            name: name,
                            x: existing?.x ?? 0,
                            y: existing?.y ?? 0,
                            width: existing?.width ?? 1920,
                            height: existing?.height ?? 1080,
                            scale: existing?.scale ?? 1,
                            transform: existing?.transform ?? 0,
                            focused: existing?.focused ?? (i === 0),
                            reserved: existing?.reserved ?? [0, 0, 0, 0],
                            activeWorkspace: existing?.activeWorkspace ?? { id: 1, name: "1" }
                        });
                        if (!root._tagData[name]) root._tagData[name] = { tags: [], occ: 0, sel: 0, urg: 0 };
                    }
                    root.monitors = newMonitors;
                    root._updateFocusedMonitor();
                } catch (e) {}
            }
        }
    }

    function updateLayers() {}

    onActiveWorkspaceChanged: {
        root._rebuildWindowList();
    }

    Connections {
        target: ToplevelManager
        function onToplevelsChanged() {
            root._rebuildWindowList();
        }
        function onActiveToplevelChanged() {
            root._rebuildWindowList();
        }
    }

    Component.onCompleted: {
        Process.exec("mmsg", ["-T"], function(result) {
            if (result.exitCode == 0) {
                var n = parseInt(result.stdout.trim());
                if (n > 0) root.tagCount = n;
            }
        });
        root._rebuildWindowList();
        updateAll();
    }
}
