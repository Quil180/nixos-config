import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    signal mouseEntered()
    signal mouseExited()
    
    // Computed hover state - includes navigation buttons
    readonly property bool isHovered: mainHover.containsMouse || 
                                       (typeof prevMouse !== 'undefined' && prevMouse.containsMouse) ||
                                       (typeof nextMouse !== 'undefined' && nextMouse.containsMouse)
    
    property var currentDate: new Date()
    property int displayedMonth: currentDate.getMonth()
    property int displayedYear: currentDate.getFullYear()
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }
    
    function getDaysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }
    
    function getFirstDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay();
    }
    
    function prevMonth() {
        if (displayedMonth === 0) {
            displayedMonth = 11;
            displayedYear--;
        } else {
            displayedMonth--;
        }
    }
    
    function nextMonth() {
        if (displayedMonth === 11) {
            displayedMonth = 0;
            displayedYear++;
        } else {
            displayedMonth++;
        }
    }

    implicitWidth: 240
    implicitHeight: 260
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    
    MouseArea {
        id: mainHover
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // Month/Year header with navigation
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "\uf053"
                color: prevMouse.containsMouse ? Theme.base04 : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.prevMonth()
                    onEntered: popup.mouseEntered()
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: Qt.locale().monthName(popup.displayedMonth) + " " + popup.displayedYear
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "\uf054"
                color: nextMouse.containsMouse ? Theme.base04 : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.nextMonth()
                    onEntered: popup.mouseEntered()
                }
            }
        }

        // Day names header
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            
            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                Text {
                    text: modelData
                    color: Theme.base03
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 4
                    }
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar grid
        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rows: 6
            spacing: 2
            
            Repeater {
                model: 42
                
                Rectangle {
                    width: (parent.width - (6 * parent.spacing)) / 7
                    height: (parent.height - (5 * parent.spacing)) / 6
                    radius: 4
                    
                    property int dayNum: {
                        var firstDay = popup.getFirstDayOfMonth(popup.displayedMonth, popup.displayedYear);
                        var daysInMonth = popup.getDaysInMonth(popup.displayedMonth, popup.displayedYear);
                        var day = index - firstDay + 1;
                        return (day > 0 && day <= daysInMonth) ? day : 0;
                    }
                    
                    property bool isToday: dayNum === popup.currentDate.getDate() &&
                                           popup.displayedMonth === popup.currentDate.getMonth() &&
                                           popup.displayedYear === popup.currentDate.getFullYear()
                    
                    color: isToday ? Theme.base0D : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: parent.dayNum > 0 ? parent.dayNum : ""
                        color: parent.isToday ? Theme.base00 : Theme.base04
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 3
                            bold: parent.isToday
                        }
                    }
                }
            }
        }
    }
}
