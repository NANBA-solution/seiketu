import SwiftUI

struct GroomingIconView: View {
    let category: GroomingCategory
    var size: CGFloat = 28

    private static let circleFill   = Color(red: 232/255, green: 241/255, blue: 255/255)
    private static let circleStroke = Color(red: 185/255, green: 214/255, blue: 255/255)

    var body: some View {
        ZStack {
            Circle()
                .fill(Self.circleFill)
                .overlay {
                    Circle().stroke(Self.circleStroke, lineWidth: 1.5)
                }
                .frame(width: size + 24, height: size + 24)
            Image(category.assetIconName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { Text(title) }
            .buttonStyle(PrimaryButtonStyle())
    }
}

struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AppTheme.accent : AppTheme.separator)
                    .frame(width: index == current ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: current)
            }
        }
    }
}
