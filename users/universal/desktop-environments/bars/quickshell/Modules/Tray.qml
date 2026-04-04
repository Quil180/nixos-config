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
            
            IconImage {
                anchors.centerIn: parent
                source: trayItemDelegate.trayItem.icon
                width: 22
                height: 22
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
