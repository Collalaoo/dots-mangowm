pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.common.models.hyprland

Singleton {
    id: root

    readonly property string shaderPath: ""
    readonly property string weakShaderPath: ""
    property bool enabled: false
    property bool weak: false

    function enable() {
        root.enabled = true;
        root.weak = false;
    }

    function enableWeak() {
        root.enabled = true;
        root.weak = true;
    }

    function disable() {
        root.enabled = false;
        root.weak = false;
    }

    function toggle() {
        if (root.enabled) disable()
        else enable()
    }

    function cycle() {
        if (!enabled) {
            enableWeak();
        } else if (weak) {
            enable();
        } else {
            disable();
        }
    }
}
