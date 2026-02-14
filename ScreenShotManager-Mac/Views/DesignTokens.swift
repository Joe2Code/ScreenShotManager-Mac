import SwiftUI

/// Design tokens for the gold-themed color palette.
enum DesignTokens {
    /// Primary gold — #D4A04A
    static let primary = Color(red: 0xD4 / 255.0, green: 0xA0 / 255.0, blue: 0x4A / 255.0)

    /// Accent gold — #E8C06A
    static let accent = Color(red: 0xE8 / 255.0, green: 0xC0 / 255.0, blue: 0x6A / 255.0)

    /// OCR highlight blue — #8AB4F8
    static let ocrHighlight = Color(red: 0x8A / 255.0, green: 0xB4 / 255.0, blue: 0xF8 / 255.0)

    /// Destructive red — #E85D5D
    static let destructive = Color(red: 0xE8 / 255.0, green: 0x5D / 255.0, blue: 0x5D / 255.0)

    /// Gold gradient for shimmer effects
    static let goldGradient = LinearGradient(
        colors: [primary, accent, primary],
        startPoint: .leading,
        endPoint: .trailing
    )
}
