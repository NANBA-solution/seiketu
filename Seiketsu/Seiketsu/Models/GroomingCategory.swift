import Foundation
import SwiftUI

enum GroomingCategory: String, CaseIterable, Codable, Identifiable {

    var themeColor: Color {
        switch self {
        case .noseHair: return Color(red: 0.039, green: 0.518, blue: 1.000)
        case .nails:    return Color(red: 0.204, green: 0.780, blue: 0.349)
        case .eyebrows: return Color(red: 1.000, green: 0.624, blue: 0.039)
        case .beard:    return Color(red: 0.369, green: 0.361, blue: 0.902)
        case .earHair:  return Color(red: 0.353, green: 0.784, blue: 0.980)
        case .haircut:  return Color(red: 1.000, green: 0.216, blue: 0.373)
        }
    }

    var sfSymbol: String {
        switch self {
        case .noseHair: return "nose"
        case .nails:    return "hand.raised.fill"
        case .eyebrows: return "eye.fill"
        case .beard:    return "mustache"
        case .earHair:  return "ear.fill"
        case .haircut:  return "scissors"
        }
    }


    case noseHair
    case nails
    case eyebrows
    case beard
    case earHair
    case haircut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noseHair: return "鼻毛"
        case .nails: return "爪"
        case .eyebrows: return "眉"
        case .beard: return "髭まわり"
        case .earHair: return "耳垢"
        case .haircut: return "散髪"
        }
    }

    /// Assets.xcassets のカスタムアイコン名
    var assetIconName: String {
        switch self {
        case .noseHair: return "IconNoseHair"
        case .nails: return "IconNails"
        case .eyebrows: return "IconEyebrows"
        case .beard: return "IconBeard"
        case .earHair: return "IconEarHair"
        case .haircut: return "IconHaircut"
        }
    }

    /// 企画書のプリセット周期（日）
    var defaultIntervalDays: Double {
        switch self {
        case .noseHair: return 7
        case .nails: return 12
        case .eyebrows: return 10
        case .beard: return 3
        case .earHair: return 17
        case .haircut: return 24
        }
    }

    var presetLabel: String {
        switch self {
        case .noseHair: return "週1回"
        case .nails: return "10〜14日"
        case .eyebrows: return "1〜2週間"
        case .beard: return "数日ごと"
        case .earHair: return "2〜3週間"
        case .haircut: return "3〜4週間"
        }
    }

    var notificationTitle: String {
        switch self {
        case .noseHair: return "鼻毛ケアの時間だ！"
        case .nails: return "爪を切る時間だ！"
        case .eyebrows: return "眉を整える時間だ！"
        case .beard: return "髭まわりを整えよう"
        case .earHair: return "耳垢ケアを忘れていませんか？"
        case .haircut: return "散髪のタイミングだ！"
        }
    }

    var notificationBody: String {
        switch self {
        case .noseHair: return "清潔感は細部から。さっとケアしよう。"
        case .nails: return "手元は意外と見られています。"
        case .eyebrows: return "眉を整えると印象が変わる！"
        case .beard: return "今日は整えて清潔感アップ。"
        case .earHair: return "気づきにくい盲点、ケアしよう。"
        case .haircut: return "清潔感をキープしよう。"
        }
    }
}
