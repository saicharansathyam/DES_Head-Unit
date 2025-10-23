.pragma library

// Calculate luminance of a color
function getLuminance(color) {
    var r = color.r
    var g = color.g
    var b = color.b

    // Convert to linear RGB
    r = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4)
    g = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4)
    b = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4)

    return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

// Calculate contrast ratio between two colors
function getContrastRatio(color1, color2) {
    var lum1 = getLuminance(color1)
    var lum2 = getLuminance(color2)

    var lighter = Math.max(lum1, lum2)
    var darker = Math.min(lum1, lum2)

    return (lighter + 0.05) / (darker + 0.05)
}

// Get contrasting text color (black or white)
function getContrastColor(backgroundColor) {
    var luminance = getLuminance(backgroundColor)
    return luminance > 0.5 ? "#000000" : "#ffffff"
}

// Check if color is dark
function isDarkColor(color) {
    var luminance = getLuminance(color)
    return luminance < 0.5
}

// Convert color to hex string
function colorToHex(color) {
    var r = Math.round(color.r * 255).toString(16).padStart(2, '0')
    var g = Math.round(color.g * 255).toString(16).padStart(2, '0')
    var b = Math.round(color.b * 255).toString(16).padStart(2, '0')
    return "#" + r + g + b
}

