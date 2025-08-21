# 私の技術ブログ

Hugoを使用して作成した技術ブログです。プログラミング、開発、学習記録などを共有します。

## 特徴

- **Hugo**: 高速な静的サイトジェネレーター
- **Anankeテーマ**: レスポンシブデザイン対応
- **日本語対応**: 日本語コンテンツに最適化
- **タグ・カテゴリ**: 効率的なコンテンツ管理
- **SEO最適化**: 検索エンジン対策

## 技術スタック

- Hugo 0.120.0+
- Anankeテーマ
- Markdown
- Tachyons CSS

## ローカルでの開発

### 前提条件

- Hugo Extended 0.120.0以上
- Git

### セットアップ

```bash
# リポジトリをクローン
git clone <your-repository-url>
cd my-blog

# 依存関係をインストール
git submodule update --init --recursive

# 開発サーバーを起動
hugo server -D
```

### 新しい投稿の作成

```bash
hugo new posts/your-post-title.md
```

## Netlifyでの公開

### 1. Gitリポジトリの準備

```bash
# Gitリポジトリを初期化
git init
git add .
git commit -m "Initial commit"

# GitHubなどのリモートリポジトリにプッシュ
git remote add origin <your-repository-url>
git push -u origin main
```

### 2. Netlifyでの設定

1. [Netlify](https://netlify.com)にサインアップ/ログイン
2. "New site from Git" をクリック
3. GitHubリポジトリを選択
4. ビルド設定：
   - Build command: `hugo`
   - Publish directory: `public`
5. "Deploy site" をクリック

### 3. カスタムドメインの設定（オプション）

1. Netlifyの管理画面で "Domain settings" を開く
2. "Add custom domain" をクリック
3. ドメイン名を入力
4. DNSレコードを設定

## ディレクトリ構造

```
my-blog/
├── content/          # ブログコンテンツ
│   └── posts/       # ブログ投稿
├── layouts/          # カスタムレイアウト
├── static/           # 静的ファイル
├── themes/           # テーマ
├── hugo.toml         # Hugo設定
├── netlify.toml      # Netlify設定
└── README.md         # このファイル
```

## 投稿の書き方

### フロントマター

```markdown
---
title: "投稿タイトル"
date: 2024-01-15T10:00:00+09:00
draft: false
description: "投稿の説明"
tags: ["タグ1", "タグ2"]
categories: ["カテゴリ"]
author: "著者名"
---
```

### Markdown記法

- 見出し: `# ## ###`
- リスト: `- * 1.`
- 強調: `**太字** *斜体*`
- コード: `` `コード` ``
- リンク: `[テキスト](URL)`

## カスタマイズ

### テーマのカスタマイズ

`themes/ananke/` ディレクトリ内のファイルを編集することで、テーマをカスタマイズできます。

### CSSの追加

`assets/css/` ディレクトリにカスタムCSSファイルを追加できます。

## トラブルシューティング

### よくある問題

1. **ビルドエラー**: Hugoのバージョンを確認
2. **テーマが適用されない**: `hugo.toml`の設定を確認
3. **画像が表示されない**: パスとファイル名を確認

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## 連絡先

- GitHub: [@your-username](https://github.com/your-username)
- ブログ: [https://your-site-name.netlify.app](https://your-site-name.netlify.app)
