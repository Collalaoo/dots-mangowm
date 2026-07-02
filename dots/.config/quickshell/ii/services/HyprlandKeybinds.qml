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

    readonly property string keybindsPath: Directories.homePath + "/.config/mango/Keybinds.conf"

    function parseKeybinds(content) {
        var binds = [];
        var groups = [];
        var lines = content.split("\n");

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();

            if (!line || line.startsWith("#")) continue;

            var m = line.match(/^bind(?:l|r)?\s*=\s*(.*)$/);
            if (!m) continue;

            var parts = m[1].split(",");
            if (parts.length < 3) continue;

            var mods = [];
            var key = "";
            var action = "";

            // Parse keybind format: mods,key,action
            var idx = 0;
            var modKeys = [];
            while (idx < parts.length && parts[idx].trim().match(/^(SUPER|CTRL|ALT|SHIFT|MOD[1-4]|mouse:\d+|mouse_down|mouse_up)$/i)) {
                modKeys.push(parts[idx].trim().toUpperCase());
                idx++;
            }
            if (idx < parts.length) key = parts[idx].trim();
            idx++;
            if (idx < parts.length) {
                var rest = parts.slice(idx).join(",").trim();
                var descMatch = rest.match(/#"(.*?)"/);
                var desc = descMatch ? descMatch[1] : "";
                var cmdMatch = rest.match(/^(.*?)(?:#|$)/);
                action = cmdMatch ? cmdMatch[1].trim() : rest;
                if (descMatch) desc = descMatch[1];

                var category = "General";
                var catMatch = desc.match(/^([^:]+):/);
                if (catMatch) {
                    category = catMatch[1].trim();
                    desc = desc.substring(catMatch[0].length).trim();
                }

                var modStr = modKeys.join("+");
                if (key) modStr = modStr ? modStr + "+" + key : key;

                var bind = {
                    description: desc || action,
                    category: category,
                    modmask: modStr,
                    key: key,
                    action: action
                };
                binds.push(bind);

                if (groups.indexOf(category) === -1) groups.push(category);
            }
        }

        root.keybinds = binds;
        root.keybindCategories = groups;
    }

    FileView {
        id: keybindsFile
        path: root.keybindsPath
        watchChanges: true
        onFileChanged: fetchBinds.running = true;
        onLoaded: {
            root.parseKeybinds(text);
        }
    }

    Process {
        id: fetchBinds
        running: true
        command: ["cat", root.keybindsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseKeybinds(text);
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: { fetchBinds.running = true; }
    }
}
