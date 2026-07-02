import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "gamepad"
    toggled: toggled

    onClicked: {
        root.toggled = !root.toggled
        if (root.toggled) {
            Quickshell.execDetached(["mmsg", "setoption", "animations:enabled", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "decoration:shadow:enabled", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "decoration:blur:enabled", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "general:gaps_in", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "general:gaps_out", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "general:border_size", "1"])
            Quickshell.execDetached(["mmsg", "setoption", "decoration:rounding", "0"])
            Quickshell.execDetached(["mmsg", "setoption", "general:allow_tearing", "1"])
        } else {
            Quickshell.execDetached(["mmsg", "reload"])
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["mmsg", "getoption", "animations:enabled"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text);
                    root.toggled = (data.int != null && data.int === 0);
                } catch (e) {
                    root.toggled = false;
                }
            }
        }
    }
    StyledToolTip {
        text: Translation.tr("Game mode")
    }
}
