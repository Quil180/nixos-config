import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property var parentWindow: null

    signal mouseEntered()
    signal mouseExited()

    readonly property bool isHovered: mainHover.hovered

    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: Math.max(trayRow.implicitWidth + 24, 120)
    implicitHeight: trayRow.implicitHeight + 24
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1

    HoverHandler {
        id: mainHover
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        Text {
            text: "\uf03a  Tray"
            color: Theme.base04
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: true
            }
            visible: SystemTray.items.length > 0
        }

        Text {
            visible: SystemTray.items.length === 0
            text: "No tray icons"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }

        Tray {
            id: trayRow
            parentWindow: popup.parentWindow
        }
    }
}
