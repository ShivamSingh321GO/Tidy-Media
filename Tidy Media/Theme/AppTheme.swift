//
//  AppTheme.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI

// MARK: - Brand Color Palette
extension Color {
    /// Primary Blue (#2879E7) - Main App Accent Color
    static let appAccent = Color(hex: "#2879E7")
    
    /// Cyan Blue (#1D9EE0) - Secondary Brand Accent
    static let appCyanBlue = Color(hex: "#1D9EE0")
    
    /// Light Cyan (#52D7E9) - Vibrant Highlights
    static let appLightCyan = Color(hex: "#52D7E9")
    
    /// Sky Blue (#8CC5F7) - Light Tints & Soft Areas
    static let appSkyBlue = Color(hex: "#8CC5F7")
    
    /// Purple (#9AA0F7) - Secondary Accent
    static let appPurple = Color(hex: "#9AA0F7")
    
    /// Pink Purple (#D37CEC) - Gradient & Highlights
    static let appPinkPurple = Color(hex: "#D37CEC")
    
    /// Magenta (#CC56DE) - Strong Vibrant Accent
    static let appMagenta = Color(hex: "#CC56DE")
    
    /// Folder Soft White (#F1F5FC) - Crisp Surface Tints
    static let appCardWhite = Color(hex: "#F1F5FC")
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
