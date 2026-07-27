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
        property bool isOccupied: workspaceData !== null

        Layout.preferredWidth: 20
        Layout.preferredHeight: parent.height
        color: "transparent"

        Text {
            id: workspacesText
            text: index + 1
            anchors.centerIn: parent
            color: parent.isFocused ? Theme.base0D : (parent.workspaceData ? Theme.base05 : Theme.base04)

            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: parent.isFocused || parent.workspaceData
            }

            Rectangle {
                width: 18
                height: 1.5
                radius: 1
                visible: parent.parent.isFocused || parent.parent.isOccupied
                color: parent.parent.isFocused ? Theme.base0D : Theme.base05
                opacity: parent.parent.isFocused ? 1.0 : 0.7
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 2
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + (index + 1 + parent.parent.offset))
            }
        }
    }
}
