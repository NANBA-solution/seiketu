import SwiftUI

enum AppTheme {
    static let background  = Color(red: 0.949, green: 0.949, blue: 0.969)
    static let surface     = Color.white
    static let primary     = Color(red: 0.11,  green: 0.11,  blue: 0.118)
    static let secondary   = Color(red: 0.424, green: 0.424, blue: 0.443)
    static let separator   = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.18)

    static let accent      = Color(red: 0.369, green: 0.361, blue: 0.902)   // #5E5CE6
    static let done        = Color(red: 0.204, green: 0.780, blue: 0.349)   // #34C759
    static let warning     = Color(red: 1.000, green: 0.624, blue: 0.039)   // #FF9F0A
    static let danger      = Color(red: 1.000, green: 0.231, blue: 0.188)   // #FF3B30

    static let cardShadow  = Color.black.opacity(0.06)

    // Legacy aliases — keeps files we haven't touched compiling
    static var navy:             Color { primary }
    static var navyLight:        Color { accent }
    static var cardBackground:   Color { surface }
    static var secondaryText:    Color { secondary }
    static var divider:          Color { separator }
    static var accentBlue:       Color { accent }
    static var doneGreen:        Color { done }
    static var iconCircleFill:   Color { accent.opacity(0.10) }
    static var iconCircleStroke: Color { .clear }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(red: 0.53, green: 0.36, blue: 0.90)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.098, green: 0.098, blue: 0.180),
                Color(red: 0.188, green: 0.133, blue: 0.408)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.accentGradient)
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
