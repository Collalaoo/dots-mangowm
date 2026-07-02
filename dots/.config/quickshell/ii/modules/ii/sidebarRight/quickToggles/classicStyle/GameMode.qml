import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "gamepad"
    toggled: false

    readonly property string mangoConfig: Directories.homePath + "/.config/mango/General.conf"

    function configSet(key, value) {
        Quickshell.execDetached(["bash", "-c",
            "grep -q '^" + key + "=' " + root.mangoConfig +
            " && sed -i 's/^" + key + "=.*/" + key + "=" + value + "/' " + root.mangoConfig +
            " || echo '" + key + "=" + value + "' >> " + root.mangoConfig
        ]);
    }

    onClicked: {
        root.toggled = !root.toggled
        if (root.toggled) {
            configSet("general.gaps_in", "0")
            configSet("general.gaps_out", "0")
            configSet("general.border_size", "1")
            configSet("decoration.rounding", "0")
            configSet("general.allow_tearing", "1")
        } else {
            configSet("general.gaps_in", "4")
            configSet("general.gaps_out", "5")
            configSet("general.border_size", "1")
            configSet("decoration.rounding", "18")
            configSet("general.allow_tearing", "1")
        }
    }

    StyledToolTip {
        text: Translation.tr("Game mode")
    }
}
