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
    property var baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"
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
        id: fetchDevices
        running: true
        command: ["mmsg", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text);
                    var kb = data.keyboards ? data.keyboards.find(function(k) { return k.main }) : null;
                    if (!kb) kb = data.keyboard;
                    if (kb) {
                        root.layoutCodes = kb.layout ? kb.layout.split(",") : [];
                        root.currentLayoutName = kb.active_keymap || "";
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: { fetchDevices.running = true; }
    }
}
