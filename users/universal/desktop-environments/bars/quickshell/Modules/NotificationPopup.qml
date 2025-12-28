import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property var notifications: []
    property int count: 0
    
    signal clearAll()
    signal dismissNotification(int id)
    signal mouseEntered()
    signal mouseExited()
    
    readonly property bool isHovered: mainHover.containsMouse
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 300
    implicitHeight: Math.min(contentColumn.height + 24, 350)
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    clip: true
    
    MouseArea {
        id: mainHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "\uf0f3  Notifications"
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                visible: popup.count > 0
                text: "Clear all"
                color: clearMouse.containsMouse ? Theme.base04 : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.clearAll()
                    onEntered: popup.mouseEntered()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.base01
        }

        // Empty state
        Text {
            visible: popup.notifications.length === 0
            text: "No notifications"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
            Layout.alignment: Qt.AlignHCenter
        }

        // Notification list
        Repeater {
            model: popup.notifications
            
            Rectangle {
                Layout.fillWidth: true
                height: notifContent.height + 12
                color: notifMouse.containsMouse ? Theme.base01 : "transparent"
                radius: 4
                
                ColumnLayout {
                    id: notifContent
                    anchors {
                        left: parent.left
                        right: dismissBtn.left
                        top: parent.top
                        margins: 6
                    }
                    spacing: 2
                    
                    Text {
                        text: modelData.appName
                        color: Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 3
                        }
                    }
                    
                    Text {
                        text: modelData.summary
                        color: Theme.base04
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 1
                            bold: true
                        }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        visible: modelData.body !== ""
                        text: modelData.body
                        color: Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }
                }
                
                Text {
                    id: dismissBtn
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    text: "\uf00d"
                    color: dismissMouse.containsMouse ? Theme.alertColor : Theme.base02
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }
                    MouseArea {
                        id: dismissMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.dismissNotification(modelData.id)
                        onEntered: popup.mouseEntered()
                    }
                }
                
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.mouseEntered()
                    propagateComposedEvents: true
                    onClicked: mouse => mouse.accepted = false
                    onPressed: mouse => mouse.accepted = false
                }
            }
        }
    }
}
