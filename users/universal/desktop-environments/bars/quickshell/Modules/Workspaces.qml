import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property int workspaceCount: 9
    property string monitorName: ""

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    property var monitor: Hyprland.monitors.values.find(m => m.name === root.monitorName)
    property int offset: monitor && monitor.activeWorkspace ? Math.floor((monitor.activeWorkspace.id - 1) / 10) * 10 : 0
    property int activeWorkspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    property int activeIndex: {
        let idx = activeWorkspaceId - 1 - offset;
        return (idx >= 0 && idx < workspaceCount) ? idx : 0;
    }

    Rectangle {
        id: activePill
        z: 0
        radius: height / 2
        color: Theme.base0D
        width: 22
        height: 22
        anchors.verticalCenter: parent.verticalCenter

        property Item targetItem: repeater.itemAt(root.activeIndex)
        x: targetItem ? targetItem.x + (targetItem.width - width) / 2 : root.activeIndex * (22 + rowLayout.spacing)

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutExpo
            }
        }
    }

    Row {
        id: rowLayout
        z: 1
        anchors.fill: parent
        spacing: 4

        Repeater {
            id: repeater
            model: root.workspaceCount

            Rectangle {
                id: delegate
                property int wsId: index + 1 + root.offset
                property var workspaceData: Hyprland.workspaces.values.find(w => w.id === wsId && w.toplevels.values.length > 0) ?? null
                property bool isFocused: root.activeIndex === index
                property bool isOccupied: workspaceData !== null

                width: 22
                height: 22
                color: "transparent"

                Text {
                    id: workspacesText
                    text: index + 1
                    anchors.centerIn: parent
                    color: delegate.isFocused ? Theme.base00 : (wsMouse.containsMouse ? Theme.base0D : (delegate.isOccupied ? Theme.base05 : Theme.base04))

                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                        bold: delegate.isFocused || delegate.isOccupied
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + delegate.wsId + " })")
                }
            }
        }
    }
}
