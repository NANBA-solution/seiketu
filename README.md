# セイケツ (SEIKETSU)

ほっとくと、おっさんになる。だらしない男のための全自動・身だしなみアラートアプリ。

## 機能（MVP）

- **6ステップ・オンボーディング**（30秒・設定不要）
- **部位別プリセット周期**（鼻毛・爪・眉・髭まわり・耳垢・散髪）
- **ホーム画面** — ステータスヘッダー、残り日数、「やった！」ボタン
- **学習ロジック** — 完了間隔から平均周期を更新し、次回通知を自動調整
- **放置ペナルティ** — 無視が続く項目は通知間隔を延長
- **ローカル通知** — サーバー不要・端末内データのみ
- **身だしなみ記録** — ケア履歴の一覧表示

## 技術スタック

| 項目 | 内容 |
|------|------|
| UI | SwiftUI |
| 最低 OS | iOS 17 |
| 通知 | `UserNotifications`（ローカル） |
| 保存 | `UserDefaults` + JSON |

## 起動方法

1. Xcode で **`Seiketsu/Seiketsu.xcodeproj`** を開く（`.xcodeproj` まで指定。親フォルダ「セイケツ」だけでは開けません）
2. 実機またはシミュレータで Run（⌘R）
3. 初回起動でオンボーディング → 通知を許可

> **署名**: Target「Seiketsu」→ Signing & Capabilities で Development Team を選択してください。

## プロジェクト構成

```
Seiketsu/
├── Seiketsu.xcodeproj
└── Seiketsu/
    ├── SeiketsuApp.swift
    ├── Models/
    ├── Services/
    ├── Theme/
    └── Views/
docs/                    # UIモック画像
セイケツ 企画書.docx
```

## リポジトリ

- GitHub: [NANBA-solution/seiketu](https://github.com/NANBA-solution/seiketu)

## ドキュメント

- `セイケツ 企画書.docx` — 企画書 Ver 1.0
- `docs/app-promo.png` — アプリ紹介UI
- `docs/onboarding-flow.png` — オンボーディングフロー
