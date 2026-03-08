import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Repeater {
    id: root

    property int workspaceCount: 9
    property string monitorName: ""

    model: workspaceCount

    Rectangle {
        property var monitor: Hyprland.monitors.values.find(m => m.name === root.monitorName)
        property int offset: monitor && monitor.activeWorkspace ? Math.floor((monitor.activeWorkspace.id - 1) / 10) * 10 : 0
        property var workspaceData: Hyprland.workspaces.values.find(workspace => workspace.id === (index + 1 + offset) && workspace.toplevels.values.length > 0) ?? null
        property bool isFocused: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id === (index + 1 + offset) : false

        Layout.preferredWidth: 20
        Layout.preferredHeight: parent.height
        color: "transparent"

        Text {
            id: workspacesText
            text: index + 1
            color: parent.isFocused ? Theme.base03 : (parent.workspaceData ? Theme.base02 : Theme.base01)

            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: true
            }

            Rectangle {
                width: 20
                height: 1
                color: parent.parent.isFocused ? Theme.base04 : Theme.base00
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + (index + 1 + parent.parent.offset))
            }
        }
    }
}
