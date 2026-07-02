pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string mangoConfigDir: Directories.homePath + "/.config/mango"

    signal reloaded()

    function set(key, value) {
        var path = root.mangoConfigDir + "/General.conf";
        var filePath = path;
        var content = Session.readFile(filePath);
        if (content === null) content = "";

        var lines = content.split("\n");
        var found = false;
        for (var i = 0; i < lines.length; i++) {
            var trimmed = lines[i].trim();
            if (trimmed.startsWith(key + "=")) {
                lines[i] = key + "=" + value;
                found = true;
                break;
            }
        }
        if (!found) {
            lines.push(key + "=" + value);
        }
        Session.writeFile(filePath, lines.join("\n"));
        root.reloaded();
    }

    function setMany(entries) {
        var path = root.mangoConfigDir + "/General.conf";
        var content = Session.readFile(path);
        if (content === null) content = "";

        var lines = content.split("\n");
        for (var key in entries) {
            var found = false;
            for (var i = 0; i < lines.length; i++) {
                var trimmed = lines[i].trim();
                if (trimmed.startsWith(key + "=")) {
                    lines[i] = key + "=" + entries[key];
                    found = true;
                    break;
                }
            }
            if (!found) {
                lines.push(key + "=" + entries[key]);
            }
        }
        Session.writeFile(path, lines.join("\n"));
        root.reloaded();
    }

    function reset(key) {
        var path = root.mangoConfigDir + "/General.conf";
        var content = Session.readFile(path);
        if (content === null) return;
        var lines = content.split("\n");
        var newLines = [];
        for (var i = 0; i < lines.length; i++) {
            var trimmed = lines[i].trim();
            if (!trimmed.startsWith(key + "=")) {
                newLines.push(lines[i]);
            }
        }
        Session.writeFile(path, newLines.join("\n"));
        root.reloaded();
    }

    function resetMany(keys) {
        var path = root.mangoConfigDir + "/General.conf";
        var content = Session.readFile(path);
        if (content === null) return;
        var lines = content.split("\n");
        var newLines = [];
        for (var i = 0; i < lines.length; i++) {
            var trimmed = lines[i].trim();
            var skip = false;
            for (var j = 0; j < keys.length; j++) {
                if (trimmed.startsWith(keys[j] + "=")) { skip = true; break; }
            }
            if (!skip) newLines.push(lines[i]);
        }
        Session.writeFile(path, newLines.join("\n"));
        root.reloaded();
    }
}
