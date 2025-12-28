import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: launcher
    
    signal closed()
    signal appLaunched(string name)
    
    property string searchText: ""
    property int selectedIndex: 0
    property var filteredApps: []
    
    implicitWidth: 600
    implicitHeight: 500
    color: Qt.rgba(
        parseInt(Theme.base00.toString().slice(1, 3), 16) / 255,
        parseInt(Theme.base00.toString().slice(3, 5), 16) / 255,
        parseInt(Theme.base00.toString().slice(5, 7), 16) / 255,
        0.95
    )
    radius: 12
    border.color: Theme.base01
    border.width: 1
    
    // Animation on appearance
    opacity: 1
    scale: 1
    
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    
    // Filter apps based on search
    function updateFilteredApps() {
        var apps = DesktopEntries.applications.values;
        if (searchText === "") {
            filteredApps = apps;
        } else {
            var lowerSearch = searchText.toLowerCase();
            filteredApps = apps.filter(function(app) {
                return app.name.toLowerCase().includes(lowerSearch) ||
                       (app.genericName && app.genericName.toLowerCase().includes(lowerSearch)) ||
                       (app.keywords && app.keywords.some(function(kw) { 
                           return kw.toLowerCase().includes(lowerSearch); 
                       }));
            });
        }
        selectedIndex = 0;
    }
    
    Component.onCompleted: updateFilteredApps()
    onSearchTextChanged: updateFilteredApps()
    
    // Keyboard handling
    Keys.onPressed: function(event) {
        var columns = 5;
        var currentRow = Math.floor(selectedIndex / columns);
        var currentCol = selectedIndex % columns;
        
        if (event.key === Qt.Key_Escape) {
            launcher.closed();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (filteredApps.length > 0 && selectedIndex < filteredApps.length) {
                var app = filteredApps[selectedIndex];
                app.execute();
                launcher.appLaunched(app.name);
                launcher.closed();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (selectedIndex + columns < filteredApps.length) {
                selectedIndex += columns;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (selectedIndex - columns >= 0) {
                selectedIndex -= columns;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (selectedIndex + 1 < filteredApps.length) {
                selectedIndex++;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (selectedIndex > 0) {
                selectedIndex--;
            }
            event.accepted = true;
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Search input
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Theme.base01
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                Text {
                    text: "\uf002"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true
                    
                    onTextChanged: launcher.searchText = text
                    
                    // Placeholder
                    Text {
                        anchors.fill: parent
                        text: "Search applications..."
                        color: Theme.base02
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        visible: searchInput.text === ""
                    }
                }
            }
        }
        
        // App grid
        GridView {
            id: appGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: (width) / 5
            cellHeight: 90
            clip: true
            
            model: launcher.filteredApps
            
            delegate: Item {
                width: appGrid.cellWidth
                height: appGrid.cellHeight
                
                property bool isSelected: index === launcher.selectedIndex
                property bool isHovered: appMouse.containsMouse
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: isSelected ? Theme.base01 : (isHovered ? Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.5) : "transparent")
                    radius: 8
                    border.color: isSelected ? Theme.base04 : "transparent"
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        // App icon
                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            source: "image://icon/" + modelData.icon
                            sourceSize.width: 48
                            sourceSize.height: 48
                            width: 48
                            height: 48
                            
                            // Fallback if no icon
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.base02
                                radius: 8
                                visible: parent.status !== Image.Ready
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name.charAt(0).toUpperCase()
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }
                        }
                        
                        // App name
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: appGrid.cellWidth - 16
                            text: modelData.name
                            color: isSelected ? Theme.base05 : Theme.base03
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                    
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: launcher.selectedIndex = index
                        onClicked: {
                            modelData.execute();
                            launcher.appLaunched(modelData.name);
                            launcher.closed();
                        }
                    }
                }
            }
            
            // Scroll indicator
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
        
        // App count
        Text {
            text: launcher.filteredApps.length + " applications"
            color: Theme.base02
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
        }
    }
    
    // Click outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: launcher.closed()
    }
    
    // Focus search on open
    function focusSearch() {
        searchInput.forceActiveFocus();
    }
}
