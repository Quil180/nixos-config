import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: popup

    property var wallpaperWidget: null

    signal wallpaperSelected()
    signal mouseEntered()
    signal mouseExited()

    onWallpaperWidgetChanged: {
        console.log("[WallpaperPicker] wallpaperWidget changed to:", wallpaperWidget);
        updateModel();
    }

    Component.onCompleted: {
        console.log("[WallpaperPicker] Component.onCompleted, wallpaperWidget:", wallpaperWidget);
        updateModel();
    }

    function updateModel() {
        if (!popup.wallpaperWidget) {
            console.log("[WallpaperPicker] updateModel: no wallpaperWidget");
            return;
        }
        var all = popup.wallpaperWidget.wallpapers;
        console.log("[WallpaperPicker] updateModel: wallpapers count:", all ? all.length : 0);
        if (!all || all.length === 0) {
            gridView.model = [];
            return;
        }
        var filter = searchInput.text.trim().toLowerCase();
        if (!filter) {
            gridView.model = all.slice();
            console.log("[WallpaperPicker] updateModel: model set to", all.length, "items (unfiltered)");
            return;
        }
        var filtered = all.filter(function(path) {
            var filename = path.split('/').pop().toLowerCase();
            return filename.indexOf(filter) !== -1;
        });
        gridView.model = filtered;
        console.log("[WallpaperPicker] updateModel: model set to", filtered.length, "items (filtered)");
    }

    Connections {
        target: popup.wallpaperWidget
        function onWallpapersChanged() {
            console.log("[WallpaperPicker] wallpapers changed, updating model");
            popup.updateModel();
        }
        function onThumbnailsUpdated() {
            console.log("[WallpaperPicker] thumbnails updated, refreshing model");
            popup.updateModel();
        }
    }

    readonly property bool isHovered: mainHover.hovered

    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 460
    implicitHeight: 380
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    clip: true

    HoverHandler {
        id: mainHover
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header section
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uf03e  Wallpaper Picker"
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // Random wallpaper button
            Rectangle {
                width: 28
                height: 28
                radius: 4
                color: randomHover.containsMouse ? Theme.base01 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf074"
                    color: randomHover.containsMouse ? Theme.base0D : Theme.base03
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }
                }

                MouseArea {
                    id: randomHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (popup.wallpaperWidget) {
                            popup.wallpaperWidget.setRandomWallpaper();
                        }
                    }
                }
            }
        }

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: Theme.base01
            radius: 6
            border.color: searchInput.activeFocus ? Theme.base0D : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\uf002"
                    color: Theme.base03
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.base05
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }
                    selectByMouse: true
                    onTextChanged: popup.updateModel()

                    Text {
                        text: "Search wallpapers..."
                        color: Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                        visible: searchInput.text.length === 0 && !searchInput.activeFocus
                    }
                }

                Text {
                    visible: searchInput.text.length > 0
                    text: "\uf00d"
                    color: clearMouse.containsMouse ? Theme.alertColor : Theme.base03
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.base01
        }

        // Empty state / Loading
        Text {
            visible: gridView.count === 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillHeight: true
            text: popup.wallpaperWidget && popup.wallpaperWidget.loading ? "Loading wallpapers..." : "No wallpapers found"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
            }
        }

        // Grid View of wallpapers
        GridView {
            id: gridView
            visible: gridView.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 144
            cellHeight: 98
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: []

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                property string wallpaperPath: modelData
                property string thumbnailPath: popup.wallpaperWidget ? popup.wallpaperWidget.getThumbnailPath(modelData) : ""
                property string fileName: {
                    var parts = modelData.split('/');
                    var name = parts[parts.length - 1];
                    return name.replace(/\.[^/.]+$/, "");
                }
                property bool isCurrent: popup.wallpaperWidget && popup.wallpaperWidget.currentWallpaper === modelData

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 6
                    color: Theme.base01
                    border.color: isCurrent ? Theme.base0D : (cardHover.containsMouse ? Theme.base0D : Theme.base02)
                    border.width: isCurrent ? 2 : 1
                    clip: true
                    scale: cardHover.containsMouse ? 1.03 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Image {
                        id: img
                        anchors.fill: parent
                        source: (thumbnailPath && thumbnailPath.length > 0) ? ("file://" + thumbnailPath) : ("file://" + modelData)
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 288
                        sourceSize.height: 196
                        asynchronous: true
                        smooth: true
                        mipmap: true

                        onStatusChanged: {
                            if (status === Image.Error && source != "file://" + modelData) {
                                source = "file://" + modelData;
                            }
                        }
                    }

                    // Bottom title overlay
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 22
                        color: Qt.rgba(0, 0, 0, 0.7)

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            verticalAlignment: Text.AlignVCenter
                            text: fileName
                            color: Theme.base05
                            font {
                                family: Theme.fontFamily
                                pixelSize: 11
                            }
                            elide: Text.ElideRight
                        }
                    }

                    // Selected checkmark badge
                    Rectangle {
                        visible: isCurrent
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 4
                        }
                        width: 18
                        height: 18
                        radius: 9
                        color: Theme.base0D

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            color: Theme.base00
                            font {
                                family: Theme.fontFamily
                                pixelSize: 10
                                bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: cardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (popup.wallpaperWidget) {
                                popup.wallpaperWidget.setWallpaper(modelData);
                            }
                            popup.wallpaperSelected();
                        }
                    }
                }
            }
        }
    }
}
