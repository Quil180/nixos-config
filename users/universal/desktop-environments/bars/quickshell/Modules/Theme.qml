pragma Singleton
import QtQuick

QtObject {
    // Base16 Color Scheme
    property color base00: "#1b1d29"
    property color base01: "#364852"
    property color base02: "#5a697c"
    property color base03: "#999da8"
    property color base04: "#cbb785"
    property color base05: "#ffdeb3"
    property color base06: "#fdefca"
    property color base07: "#f5f0ed"
    property color base08: "#8c929e"
    property color base09: "#8b919d"
    property color base0A: "#a48f60"
    property color base0B: "#898f9b"
    property color base0C: "#8d939f"
    property color base0D: "#8a909c"
    property color base0E: "#909196"
    property color base0F: "#8b919d"

    // Dynamic Color Updating
    function updateColors(palette) {
        if (!palette) return;
        console.log("[Theme] Applying new color scheme palette");
        if (palette.base00) base00 = palette.base00;
        if (palette.base01) base01 = palette.base01;
        if (palette.base02) base02 = palette.base02;
        if (palette.base03) base03 = palette.base03;
        if (palette.base04) base04 = palette.base04;
        if (palette.base05) base05 = palette.base05;
        if (palette.base06) base06 = palette.base06;
        if (palette.base07) base07 = palette.base07;
        if (palette.base08) base08 = palette.base08;
        if (palette.base09) base09 = palette.base09;
        if (palette.base0A) base0A = palette.base0A;
        if (palette.base0B) base0B = palette.base0B;
        if (palette.base0C) base0C = palette.base0C;
        if (palette.base0D) base0D = palette.base0D;
        if (palette.base0E) base0E = palette.base0E;
        if (palette.base0F) base0F = palette.base0F;
    }

    // Dynamic Accent & Alert Colors (Material-You / Caelestia aesthetic)
    property color accentColor: base0D
    property color alertColor: base08
    property color warningColor: base0A
    property color successColor: base0B
    property color blueColor: base0D
    property color orangeColor: base09

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
