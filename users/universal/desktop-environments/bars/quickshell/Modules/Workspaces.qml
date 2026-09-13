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

    // This Hyprland setup uses per-monitor relative workspaces ("r~N", see the
    // SUPER+1..0 binds in hyprland.lua). Hyprland resolves "r~N" to the Nth
    // workspace on the focused monitor by counting absolute ids 1,2,3,... and
    // skipping only the ids in use by OTHER monitors (free id gaps count, so the
    // Nth workspace on a monitor is NOT simply the Nth workspace id).
    // relativeSlotOf() mirrors that counting exactly and returns the 0-based
    // relative slot of a workspace on its own monitor:
    //     slot = id - 1 - (# off-monitor ids below it)
    // (free ids and the monitor's own ids occupy slots, only off-monitor ids shift it).
    function relativeSlotOf(ws) {
        if (!ws || ws.id <= 0 || ws.monitor == null) return -1;
        let offset = 0;
        for (let w of Hyprland.workspaces.values) {
            if (w.id <= 0) continue;             // special/named workspaces
            if (w.id >= ws.id) continue;
            if (w.monitor !== ws.monitor) offset++;
        }
        return ws.id - 1 - offset;
    }

    property int activeWorkspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    property int activeIndex: {
        let idx = root.relativeSlotOf(monitor && monitor.activeWorkspace);
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
                property int wsId: index + 1
                property var workspaceData: Hyprland.workspaces.values.find(w =>
                    w.id > 0 && w.monitor != null && w.monitor.name === root.monitorName
                    && root.relativeSlotOf(w) === index
                    && w.toplevels.values.length > 0
                ) ?? null
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
                    // Focus the Nth relative workspace of this monitor (like the
                    // SUPER+N binds), not the absolute workspace id.
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = \"r~" + delegate.wsId + "\" })")
                }
            }
        }
    }
}