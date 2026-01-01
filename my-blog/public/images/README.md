# 画像の追加方法

このフォルダ（`static/images`）に画像ファイルを配置することで、ブログ記事で画像を使用できます。

## 画像の追加方法

### 方法1: フロントマターで`featured_image`を指定（記事一覧用）

記事のフロントマターに`featured_image`を追加すると、記事一覧ページや記事のヘッダーに画像が表示されます。

```markdown
---
title: "記事のタイトル"
date: 2025-01-01T10:00:00+09:00
draft: false
featured_image: "/images/your-image.jpg"
description: "記事の説明"
---
```

**パスの指定方法:**
- `static`フォルダ内のファイルは、ルートパス（`/`）から始めます
- 例: `static/images/photo.jpg` → `/images/photo.jpg`

### 方法2: Markdown本文内で画像を表示

記事の本文内に画像を表示するには、Markdownの画像構文を使用します。

```markdown
![画像の説明テキスト](/images/your-image.jpg)
```

**オプション: 画像のサイズを調整**

HTMLタグを使用して画像のサイズを調整することもできます：

```html
<img src="/images/your-image.jpg" alt="画像の説明" width="500">
```

または、CSSクラスを使用：

```html
<img src="/images/your-image.jpg" alt="画像の説明" class="img-responsive">
```

### 方法3: 外部URLから画像を参照

外部の画像URLを直接使用することもできます：

```markdown
![画像の説明](https://example.com/image.jpg)
```

## 画像ファイルの配置場所

- **`static/images/`**: すべての記事で共有する画像を配置
- **記事フォルダ内**: 特定の記事専用の画像を配置（Page Bundle方式）

## 推奨事項

1. **ファイル名**: わかりやすい名前を使用（例: `lazarus-challenge-2026.jpg`）
2. **画像サイズ**: ウェブ用に最適化（通常、幅1000px以下が推奨）
3. **ファイル形式**: JPG、PNG、WebPなど、一般的な形式を使用
4. **alt属性**: アクセシビリティのため、必ず説明テキストを追加

## 使用例

### 例1: フロントマターでfeatured_imageを指定

```markdown
---
title: "生存報告。そして来年、私はLazarusの修羅に入る。"
date: 2025-12-30T17:21:32+09:00
draft: false
featured_image: "/images/lazarus-challenge.jpg"
description: "ブログが生きていることを報告し、2026年にLazarusで100日間毎日アプリを作るチャレンジを宣言します。"
tags: ["ブログ", "Lazarus", "チャレンジ", "2026"]
---
```

### 例2: 本文内に画像を追加

```markdown
## チャレンジの準備

![Lazarus IDEのスクリーンショット](/images/lazarus-ide.png)

上記の画像は、Lazarus IDEの画面です。
```

