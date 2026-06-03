# セイケツ LP — Vercel 公開手順

## 事前準備（GitHub に上げる）

LP がまだリポジトリに無い場合:

```bash
cd "/Users/apple/Desktop/セイケツ"
git add app-store-lp/
git commit -m "docs: App Store 申請用 LP を追加"
git push origin main
```

---

## 方法 A: Vercel ダッシュボード（おすすめ）

### 1. アカウント

1. https://vercel.com を開く
2. **Sign Up** → **Continue with GitHub**
3. GitHub 連携を許可

### 2. プロジェクト作成

1. **Add New…** → **Project**
2. リポジトリ **`NANBA-solution/seiketu`** を Import
3. **Configure Project** で次を設定:

| 項目 | 値 |
|------|-----|
| Framework Preset | **Other** |
| Root Directory | **Edit** → `app-store-lp` を選択 |
| Build Command | （空のまま） |
| Output Directory | （空のまま） |
| Install Command | （空のまま） |

4. **Deploy** をクリック

1〜2分で完了します。

### 3. 公開 URL の確認

デプロイ後、例:

- トップ: `https://seiketu-xxxx.vercel.app/`
- プライバシー: `https://seiketu-xxxx.vercel.app/privacy.html`
- 利用規約: `https://seiketu-xxxx.vercel.app/terms.html`

**Settings → Domains** で名前を変えたり、独自ドメインを追加できます。

### 4. App Store Connect に登録

| 項目 | 登録する URL |
|------|----------------|
| プライバシーポリシー URL | `https://（あなたのドメイン）/privacy.html` |
| サポート URL | `https://（あなたのドメイン）/` |
| 連絡先 | nanbacoltd.95@gmail.com |

---

## 方法 B: Vercel CLI

```bash
npm i -g vercel
cd "/Users/apple/Desktop/セイケツ/app-store-lp"
vercel login
vercel          # 初回: プロジェクト名などを聞かれる
vercel --prod   # 本番 URL に公開
```

CLI だけでデプロイする場合、**リポジトリ連携は不要**です（`app-store-lp` フォルダから直接アップロード）。

---

## 更新の流れ

**GitHub 連携した場合**

```bash
# LP を編集したあと
git add app-store-lp/
git commit -m "update: LP 文言修正"
git push origin main
```

→ Vercel が自動で再デプロイ（数秒〜1分）。

**CLI の場合**

```bash
cd app-store-lp
vercel --prod
```

---

## うまくいかないとき

| 症状 | 対処 |
|------|------|
| 404 | Root Directory が `app-store-lp` になっているか確認 |
| 画像が出ない | `images/app-icon.png` が push されているか確認 |
| 古いページが見える | ブラウザのスーパーリロード（⇧⌘R） |

---

## ローカル確認

```bash
cd app-store-lp
python3 -m http.server 8765 --bind 127.0.0.1
```

http://127.0.0.1:8765/
