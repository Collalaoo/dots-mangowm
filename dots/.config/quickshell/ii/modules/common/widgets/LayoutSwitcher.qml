pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string currentLayout: "tile"
    property bool cycleOnClick: false

    signal layoutChanged(string layout)

    readonly property var layouts: [
        { id: "tile",     label: "Tile",      icon: "⊞" },
        { id: "monocle",  label: "Monocle",   icon: "⊟" },
        { id: "dwindle",  label: "Dwindle",   icon: "⊡" },
        { id: "grid",     label: "Grid",      icon: "⊞" },
        { id: "spiral",   label: "Spiral",    icon: "⟳" },
        { id: "float",    label: "Float",     icon: "⊕" },
    ]

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: fetchLayout()
    }

    function fetchLayout() {
        Process.exec("mmsg", ["-g", "-l"], function(result) {
            if (result.exitCode == 0 && result.stdout) {
                var raw = result.stdout.trim()
                var id = raw
                if (raw.indexOf(":") >= 0) {
                    var parts = raw.split(":")
                    if (parts.length > 1) id = parts[1].toLowerCase()
                }
                if (id != root.currentLayout) {
                    root.currentLayout = id
                    root.layoutChanged(id)
                }
            }
        })
    }

    function switchTo(layoutId) {
        Process.exec("mmsg", ["-s", "-l", layoutId], function() {
            root.currentLayout = layoutId
            root.layoutChanged(layoutId)
        })
    }

    function cycle() {
        var ids = layouts.map(function(l) { return l.id })
        var idx = ids.indexOf(root.currentLayout)
        if (idx < 0) idx = 0
        var next = (idx + 1) % ids.length
        switchTo(ids[next])
    }

    RowLayout {
        anchors.fill: parent
        spacing: 4

        StyledText {
            text: {
                for (var i = 0; i < root.layouts.length; i++) {
                    if (root.layouts[i].id == root.currentLayout)
                        return root.layouts[i].icon + " " + root.layouts[i].label
                }
                return root.currentLayout
            }
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.small
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.cycleOnClick) {
                    root.cycle()
                } else {
                    layoutPanel.toggle()
                }
            }
        }
    }

    Popup {
        id: layoutPanel
        width: 280
        height: 340
        modal: true

        background: Rectangle {
            color: Appearance.colors.colBackgroundSurfaceContainer
            radius: Appearance.rounding.large
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.sizes.elevationMargin
            spacing: 8

            StyledText {
                text: Translation.tr("Layouts")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.medium
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Repeater {
                    model: root.layouts

                    delegate: Rectangle {
                        id: layoutDelegate
                        required property var modelData
                        width: (layoutPanel.width - Appearance.sizes.elevationMargin * 2 - 16) / 3
                        height: 72
                        radius: Appearance.rounding.medium
                        color: modelData.id == root.currentLayout
                            ? ColorUtils.transparentize(Appearance.colors.colSecondary, 0.3)
                            : Appearance.colors.colLayer1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            StyledText {
                                text: layoutDelegate.modelData.icon
                                color: modelData.id == root.currentLayout
                                    ? Appearance.colors.colOnSecondary
                                    : Appearance.colors.colOnLayer1
                                font.pixelSize: 24
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: layoutDelegate.modelData.label
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: layoutDelegate.color = modelData.id == root.currentLayout
                                ? ColorUtils.transparentize(Appearance.colors.colSecondary, 0.4)
                                : Appearance.colors.colLayer1Hover
                            onExited: layoutDelegate.color = modelData.id == root.currentLayout
                                ? ColorUtils.transparentize(Appearance.colors.colSecondary, 0.3)
                                : Appearance.colors.colLayer1
                            onClicked: root.switchTo(layoutDelegate.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
