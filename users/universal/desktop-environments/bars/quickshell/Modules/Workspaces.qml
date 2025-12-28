import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Repeater {
    id: root

    property int workspaceCount: 9

    model: workspaceCount

    Rectangle {
        property var workspaceData: Hyprland.workspaces.values.find(workspace => workspace.id === index + 1 && workspace.toplevels.values.length > 0) ?? null
        property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)

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
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
        }
    }
}
