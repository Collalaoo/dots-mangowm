pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

Singleton {
    id: root

    property var bindings: []

    signal reloaded()

    readonly property string keybindsPath: Directories.homePath + "/.config/mango/Keybinds.conf"

    function parseKeybinds(content) {
        var binds = [];
        var lines = content.split("\n");

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line || line.startsWith("#")) continue;

            var m = line.match(/^bind(?:l|r)?\s*=\s*(.*)$/);
            if (!m) continue;

            binds.push({ raw: m[1] });
        }

        root.bindings = binds;
        root.reloaded();
    }

    function fetch() {
        Process.exec("cat", [root.keybindsPath], function(result) {
            if (result.exitCode != 0) return
            root.parseKeybinds(result.stdout);
        })
    }

    Component.onCompleted: fetch()
}
