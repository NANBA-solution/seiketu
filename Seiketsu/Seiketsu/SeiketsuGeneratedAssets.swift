import SwiftUI

enum SeiketsuAssetPalette {
    static let navy = Color(red: 11 / 255, green: 29 / 255, blue: 58 / 255)
    static let blue = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)
    static let mint = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    static let coral = Color(red: 244 / 255, green: 114 / 255, blue: 114 / 255)
    static let lightBlue = Color(red: 232 / 255, green: 240 / 255, blue: 254 / 255)
    static let card = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
}

enum SeiketsuIconKind: String, CaseIterable, Identifiable {
    case brush
    case nailClipper
    case earPick
    case scissors
    case bell
    case calendar
    case chart
    case settings
    case privacy
    case help
    case checkCircle
    case plus
    case edit
    case share
    case backChevron
    case forwardChevron

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .brush: "paintbrush"
        case .nailClipper: "hand.raised"
        case .earPick: "ear"
        case .scissors: "scissors"
        case .bell: "bell"
        case .calendar: "calendar"
        case .chart: "chart.bar"
        case .settings: "gearshape"
        case .privacy: "shield"
        case .help: "questionmark.circle"
        case .checkCircle: "checkmark.circle"
        case .plus: "plus.circle.fill"
        case .edit: "pencil"
        case .share: "square.and.arrow.up"
        case .backChevron: "chevron.left"
        case .forwardChevron: "chevron.right"
        }
    }
}

struct SeiketsuIconView: View {
    let kind: SeiketsuIconKind
    var size: CGFloat = 24
    var primary: Color = SeiketsuAssetPalette.navy
    var secondary: Color = SeiketsuAssetPalette.blue

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(kind == .plus ? primary : secondary)
            .frame(width: size + 12, height: size + 12)
    }
}

struct SeiketsuIconGridView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(SeiketsuIconKind.allCases) { kind in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        SeiketsuIconView(kind: kind, size: 28)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SeiketsuAssetPalette.lightBlue, lineWidth: 1)
                    )
                    .frame(height: 74)
            }
        }
        .padding(16)
        .background(.white)
    }
}

enum SeiketsuIllustrationKind: String, CaseIterable, Identifiable {
    case mirror
    case phoneChecklist
    case brushingHair
    case trimmingNails
    case earCleaning
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mirror: "鏡チェック"
        case .phoneChecklist: "チェック確認"
        case .brushingHair: "髪を整える"
        case .trimmingNails: "爪ケア"
        case .earCleaning: "耳ケア"
        case .done: "完了"
        }
    }

    var symbol: String {
        switch self {
        case .mirror: "person.crop.square"
        case .phoneChecklist: "checklist"
        case .brushingHair: "comb"
        case .trimmingNails: "scissors"
        case .earCleaning: "ear"
        case .done: "checkmark.seal.fill"
        }
    }
}

struct SeiketsuIllustrationCard: View {
    let kind: SeiketsuIllustrationKind

    private var accent: Color {
        switch kind {
        case .done: SeiketsuAssetPalette.mint
        case .trimmingNails: SeiketsuAssetPalette.coral
        default: SeiketsuAssetPalette.blue
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(SeiketsuAssetPalette.lightBlue)
                    .frame(width: 72, height: 72)
                Image(systemName: kind.symbol)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(accent)
            }
            Text(kind.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SeiketsuAssetPalette.navy)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(12)
        .background(SeiketsuAssetPalette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SeiketsuAssetPalette.lightBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SeiketsuIllustrationGridView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SeiketsuIllustrationKind.allCases) { kind in
                SeiketsuIllustrationCard(kind: kind)
            }
        }
    }
}

enum SeiketsuSwatchKind: String, CaseIterable, Identifiable {
    case plain
    case cardShadow
    case blueGradient
    case dots
    case diagonal
    case glow

    var id: String { rawValue }
}

struct SeiketsuSwatchView: View {
    let kind: SeiketsuSwatchKind

    var body: some View {
        ZStack {
            switch kind {
            case .plain:
                RoundedRectangle(cornerRadius: 18)
                    .fill(SeiketsuAssetPalette.card)
            case .cardShadow:
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .shadow(color: SeiketsuAssetPalette.navy.opacity(0.12), radius: 8, y: 4)
            case .blueGradient:
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 143 / 255, green: 176 / 255, blue: 1.0),
                                Color(red: 220 / 255, green: 232 / 255, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            case .dots:
                RoundedRectangle(cornerRadius: 18)
                    .fill(SeiketsuAssetPalette.card)
                dotPattern
            case .diagonal:
                RoundedRectangle(cornerRadius: 18)
                    .fill(SeiketsuAssetPalette.card)
                diagonalPattern
            case .glow:
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SeiketsuAssetPalette.lightBlue, .white],
                            center: .center,
                            startRadius: 8,
                            endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
            }
        }
        .frame(height: 130)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SeiketsuAssetPalette.lightBlue, lineWidth: 1)
        )
    }

    private var dotPattern: some View {
        GeometryReader { geo in
            let cols = Int(geo.size.width / 18)
            let rows = Int(geo.size.height / 18)
            ForEach(0 ..< rows, id: \.self) { row in
                ForEach(0 ..< cols, id: \.self) { col in
                    Circle()
                        .fill(SeiketsuAssetPalette.lightBlue.opacity(0.8))
                        .frame(width: 3, height: 3)
                        .position(x: CGFloat(col) * 18 + 9, y: CGFloat(row) * 18 + 9)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var diagonalPattern: some View {
        GeometryReader { geo in
            let count = Int((geo.size.width + geo.size.height) / 12)
            ForEach(0 ..< count, id: \.self) { i in
                Path { path in
                    let x = CGFloat(i * 12) - geo.size.height
                    path.move(to: CGPoint(x: x, y: geo.size.height))
                    path.addLine(to: CGPoint(x: x + geo.size.height, y: 0))
                }
                .stroke(SeiketsuAssetPalette.lightBlue.opacity(0.7), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SeiketsuSwatchGridView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SeiketsuSwatchKind.allCases) { kind in
                SeiketsuSwatchView(kind: kind)
            }
        }
    }
}

struct SeiketsuGeneratedAssetsShowcase: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Seiketsu Swift Assets")
                    .font(.title3.bold())
                    .foregroundStyle(SeiketsuAssetPalette.navy)
                SeiketsuIconGridView()
                SeiketsuIllustrationGridView()
                SeiketsuSwatchGridView()
            }
            .padding(16)
        }
        .background(Color.white)
    }
}

#Preview {
    SeiketsuGeneratedAssetsShowcase()
}
