pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: ""
    property string currentLayoutCode: ""
    property string baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"
    property bool needsLayoutRefresh: false

    onCurrentLayoutNameChanged: root.updateLayoutCode()

    function updateLayoutCode() {
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName];
        } else {
            getLayoutProc.running = true;
        }
    }

    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                var target = root.currentLayoutName;
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line || line.startsWith("!")) continue;
                    var m = line.match(/^\s*(\S+)\s+(.+)$/);
                    if (m && m[2] === target) {
                        root.cachedLayoutCodes[m[2]] = m[1];
                        root.currentLayoutCode = m[1];
                        return;
                    }
                    var mv = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/);
                    if (mv && mv[3] === target) {
                        root.cachedLayoutCodes[mv[3]] = mv[2] + mv[1];
                        root.currentLayoutCode = mv[2] + mv[1];
                        return;
                    }
                }
            }
        }
    }

    Process {
        id: fetchKbLayout
        running: true
        command: ["mmsg", "-g", "-k"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var line = text.trim();
                    var parts = line.split(/\s+/);
                    if (parts.length >= 3 && parts[1] === "kb_layout") {
                        var layout = parts.slice(2).join(" ");
                        var codes = layout.split(/[,;+]/);
                        var prevLength = root.layoutCodes.length;
                        root.layoutCodes = codes.map(function(c) { return c.trim(); }).filter(function(c) { return c.length > 0; });
                        if (codes.length > 0) {
                            var activeLayout = codes[0].trim();
                            if (activeLayout !== root.currentLayoutName) {
                                root.currentLayoutName = activeLayout;
                            }
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: { fetchKbLayout.running = true; }
    }
}
