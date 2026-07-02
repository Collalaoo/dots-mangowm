pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var keybinds: []
    property var keybindCategories: []

    Process {
        id: fetchBinds
        running: true
        command: ["mmsg", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keybinds = JSON.parse(text);
                    var groups = [];
                    for (var i = 0; i < root.keybinds.length; i++) {
                        var bind = root.keybinds[i].description || "";
                        var group = bind.substring(0, bind.indexOf(":"));
                        if (group.length > 0 && groups.indexOf(group) === -1)
                            groups.push(group);
                    }
                    root.keybindCategories = groups;
                } catch (e) {
                    console.error("[Keybinds] Error parsing:", e);
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: { fetchBinds.running = true; }
    }
}
