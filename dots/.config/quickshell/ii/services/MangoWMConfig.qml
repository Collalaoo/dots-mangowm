pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io

Singleton {
    id: root

    readonly property string mangoConfigDir: Directories.homePath + "/.config/mango"

    signal reloaded()

    function get(key) {
        var result = Process.execSync("grep", ["^" + key + "=", root.mangoConfigDir + "/General.conf"]);
        if (result.exitCode == 0) {
            var line = result.stdout.trim();
            var eq = line.indexOf("=");
            if (eq >= 0) return line.substring(eq + 1).trim();
        }
        return null
    }

    function set(key, value) {
        Process.exec("bash", ["-c", "grep -q '^" + key + "=' " + root.mangoConfigDir + "/General.conf && sed -i 's/^" + key + "=.*/" + key + "=" + value + "/' " + root.mangoConfigDir + "/General.conf || echo '" + key + "=" + value + "' >> " + root.mangoConfigDir + "/General.conf"], function() {
            root.reloaded()
        })
    }

    function reset(key) {
        Process.exec("sed", ["-i", "/^" + key + "=/d", root.mangoConfigDir + "/General.conf"], function() {
            root.reloaded()
        })
    }

    function reload() {
        root.reloaded()
    }
}
