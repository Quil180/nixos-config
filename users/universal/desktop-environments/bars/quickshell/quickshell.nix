{
  pkgs,
  inputs,
  system,
  config,
  ...
}:
{
  home.packages = [
    inputs.quickshell.packages.${system}.default
    pkgs.jq # json parsing
  ];

  xdg = {
    desktopEntries."org.quickshell" = {
      name = "Quickshell";
      exec = "quickshell";
      noDisplay = true;
    };
    configFile = {
      "quickshell/bar.qml" = {
        # source = ./bar.qml;
        text = with config.lib.stylix.colors.withHashtag; ''
          import Quickshell
          import Quickshell.Wayland
          import Quickshell.Hyprland
          import QtQuick
          import QtQuick.Layouts

          PanelWindow {
              anchors.top: true
              anchors.left: true
              anchors.right: true
              implicitHeight: 30
              color: "${base00}"

              RowLayout {
                  anchors.fill: parent
                  anchors.margins: 8

                  Repeater {
                      model: 9

                      Text {
                          property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                          property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                          text: index + 1
                          color: isActive ? "${base03}" : (ws ? "${base02}" : "${base01}")
                          font { pixelSize: 14; bold: true }

                          MouseArea {
                              anchors.fill: parent
                              onClicked: Hyprland.dispatch("workspace " + (index + 1))
                          }
                      }
                  }

                  Item { Layout.fillWidth: true }
              }
          }
        '';
        force = true;
      };
    };
  };
}
