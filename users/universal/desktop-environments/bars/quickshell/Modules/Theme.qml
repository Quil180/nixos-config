pragma Singleton
import QtQuick

QtObject {
    // Base16 Color Scheme
    readonly property color base00: "#1b1d29"
    readonly property color base01: "#364852"
    readonly property color base02: "#5a697c"
    readonly property color base03: "#999da8"
    readonly property color base04: "#cbb785"
    readonly property color base05: "#ffdeb3"
    readonly property color base06: "#fdefca"
    readonly property color base07: "#f5f0ed"
    readonly property color base08: "#8c929e"
    readonly property color base09: "#8b919d"
    readonly property color base0A: "#a48f60"
    readonly property color base0B: "#898f9b"
    readonly property color base0C: "#8d939f"
    readonly property color base0D: "#8a909c"
    readonly property color base0E: "#909196"
    readonly property color base0F: "#8b919d"

    // Alert Colors
    readonly property color alertColor: "#CD5C5C"
    readonly property color successColor: "#7ec699"
    readonly property color warningColor: "#e5c07b"
    readonly property color blueColor: "#61afef"
    readonly property color orangeColor: "#d19a66"

    // Typography
    readonly property string fontFamily: "Iosevka Nerd Font"
    readonly property int fontSize: 16
    
    // Gradient color function for usage stats (0-100): green → yellow → red
    function usageColor(value) {
        if (value < 50) {
            // Green to Yellow (0-50)
            var t = value / 50;
            return Qt.rgba(
                0.49 + t * 0.4,  // R: 0.49 → 0.89
                0.78 - t * 0.03, // G: 0.78 → 0.75
                0.60 - t * 0.12, // B: 0.60 → 0.48
                1
            );
        } else {
            // Yellow to Red (50-100)
            var t2 = (value - 50) / 50;
            return Qt.rgba(
                0.89 - t2 * 0.09, // R: 0.89 → 0.80
                0.75 - t2 * 0.39, // G: 0.75 → 0.36
                0.48 - t2 * 0.12, // B: 0.48 → 0.36
                1
            );
        }
    }
    
    // Gradient color function for temperature: blue → orange → red
    function tempColor(value) {
        if (value < 50) {
            return blueColor;
        } else if (value < 70) {
            // Blue to Orange (50-70)
            var t = (value - 50) / 20;
            return Qt.rgba(
                0.38 + t * 0.44, // R: 0.38 → 0.82
                0.69 - t * 0.09, // G: 0.69 → 0.60
                0.94 - t * 0.54, // B: 0.94 → 0.40
                1
            );
        } else {
            // Orange to Red (70-100)
            var t2 = (value - 70) / 30;
            return Qt.rgba(
                0.82 - t2 * 0.02, // R: 0.82 → 0.80
                0.60 - t2 * 0.24, // G: 0.60 → 0.36
                0.40 - t2 * 0.04, // B: 0.40 → 0.36
                1
            );
        }
    }
}
