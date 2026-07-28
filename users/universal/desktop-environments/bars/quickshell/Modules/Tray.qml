import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: tray
    spacing: 8
    
    // Pass the window from the main bar config
    property var parentWindow
    
    Repeater {
        model: SystemTray.items
        
        delegate: MouseArea {
            id: trayItemDelegate
            width: 24
            height: 24
            
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            // The item from the SystemTray service
            property var trayItem: modelData
            
            Rectangle {
                id: trayHoverBg
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: width / 2
                color: Modules.Theme.base0D
                opacity: trayItemDelegate.containsMouse ? 0.20 : 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            IconImage {
                anchors.centerIn: parent
                source: trayItemDelegate.trayItem.icon
                width: 18
                height: 18
            }
            
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    trayItemDelegate.trayItem.activate();
                } else if (mouse.button === Qt.RightButton) {
                    // display(parentWindow, x, y)
                    // Coordinates relative to the parent window
                    const pos = trayItemDelegate.mapToItem(tray.parentWindow.contentItem, mouse.x, mouse.y);
                    
                    if (typeof trayItemDelegate.trayItem.display === 'function') {
                        trayItemDelegate.trayItem.display(tray.parentWindow, pos.x, pos.y);
                    } else if (typeof trayItemDelegate.trayItem.contextMenu === 'function') {
                        trayItemDelegate.trayItem.contextMenu();
                    }
                } else if (mouse.button === Qt.MiddleButton) {
                    trayItemDelegate.trayItem.secondaryActivate();
                }
            }
        }
    }
}
