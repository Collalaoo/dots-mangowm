pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    signal reloaded()

    function set(key, value) {
        Process.exec("mmsg", ["setoption", key, value], function() {
            root.reloaded()
        })
    }

    function setMany(entries) {
        var cmds = [];
        for (var key in entries) {
            cmds.push("setoption", key, entries[key]);
        }
        if (cmds.length > 0)
            Process.exec("mmsg", cmds, function() { root.reloaded() });
    }

    function reset(key) {
        Process.exec("mmsg", ["resetoption", key], function() {
            root.reloaded()
        })
    }

    function resetMany(keys) {
        var cmds = ["resetoption"];
        for (var i = 0; i < keys.length; i++) cmds.push(keys[i]);
        if (cmds.length > 1)
            Process.exec("mmsg", cmds, function() { root.reloaded() });
    }
}
