pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Tiling layout switcher widget (like Noctalia mango-layouts)

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
                // normalize: "1:T" → "tile", "DW" → "dwindle"
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

    // Bar widget display
    RowLayout {
        anchors.fill: parent
        spacing: 4

        Text {
            text: {
                for (var i = 0; i < root.layouts.length; i++) {
                    if (root.layouts[i].id == root.currentLayout)
                        return root.layouts[i].icon + " " + root.layouts[i].label
                }
                return "⊞ " + root.currentLayout
            }
            color: "#D9E0EE"
            font.pixelSize: 13
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.cycleOnClick) {
                    root.cycle()
                } else {
                    // open panel
                    layoutPanel.toggle()
                }
            }
        }
    }

    // Panel popup
    Popup {
        id: layoutPanel
        width: 280
        height: 320
        modal: true

        Rectangle {
            anchors.fill: parent
            color: "#1E202B"
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Layouts"
                    color: "#D9E0EE"
                    font.pixelSize: 16
                    font.bold: true
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Repeater {
                        model: root.layouts

                        delegate: Rectangle {
                            width: (layoutPanel.width - 32) / 3
                            height: 72
                            radius: 8
                            color: modelData.id == root.currentLayout ? "#0DB7D455" : "#313136"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: modelData.icon
                                    color: "#D9E0EE"
                                    font.pixelSize: 24
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: "#D9E0EE"
                                    font.pixelSize: 11
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.switchTo(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
