# GitHub Actions で TestFlight に上げる（セイケツ）

**2026年4月時点** — App Store 提出には **iOS 26 SDK（Xcode 26 以上）** が必要です。  
MacBook Air 2018 などローカルに Xcode 26 が入らない場合、GitHub の **`macos-26`** ランナーでビルド・アップロードします。

## 1. API キーを作る（初回のみ）

1. [App Store Connect](https://appstoreconnect.apple.com) → **ユーザとアクセス** → **統合** → **App Store Connect API**
2. **＋** でキー作成（名前例: `GitHub Actions`、アクセス: **App マネージャ** 以上）
3. **Issuer ID** をメモ
4. **キー ID** をメモ
5. **.p8 ファイルをダウンロード**（再ダウンロード不可）

## 2. GitHub Secrets を登録

リポジトリ `NANBA-solution/seiketu` → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret 名 | 値 |
|-----------|-----|
| `APPSTORE_ISSUER_ID` | Connect の Issuer ID |
| `APPSTORE_API_KEY_ID` | キー ID（例: `ABC123XYZ`） |
| `APPSTORE_API_PRIVATE_KEY` | `.p8` の中身全体、または base64 化した文字列 |
| `DEVELOPMENT_TEAM` | `54YGGGZ8F6` |

### .p8 を Secret に入れる方法

**方法 A（おすすめ）** — ターミナルで base64:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

クリップボードの内容を `APPSTORE_API_PRIVATE_KEY` に貼る。

**方法 B** — `.p8` をテキストエディタで開き、`-----BEGIN PRIVATE KEY-----` から末尾までコピーして貼る。

## 3. コードを push

```bash
cd "/Users/apple/Desktop/セイケツ"
git add .github/workflows/ios-testflight.yml ci/
git commit -m "ci: GitHub Actions で TestFlight アップロード"
git push origin main
```

## 4. ワークフローを実行

1. GitHub → **Actions** タブ
2. 左の **iOS TestFlight Upload**
3. **Run workflow** → branch `main` → **Run workflow**

緑のチェックが付いたら成功。

## 5. App Store Connect で確認

1. **TestFlight** または **App Store** → **セイケツ**
2. ビルド **1.0.0 (run番号)** が **Processing** → 完了まで待つ
3. バージョンにビルドを紐付け → **審査用に追加**

## トラブルシュート

| エラー | 対処 |
|--------|------|
| secret が未設定 | 上記 4 つの Secret を再確認 |
| Signing / provisioning | API キーの権限を **App マネージャ** に。Bundle ID `lab.nanba.seiketsu` が Developer に登録済みか |
| 重複ビルド番号 | 再実行するたび `github.run_number` が増えるので通常は解消 |
| Export failed | Actions ログの `xcodebuild -exportArchive` を確認 |

## 手動だけ実行したい場合

`ios-testflight.yml` の `push:` を削除し、`workflow_dispatch` のみにすると、ボタン実行だけになります。
