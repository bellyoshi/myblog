---
title: "Pas2JSでオートシェイプ風ホワイトボードを作成 - Day33"
date: 2026-02-02T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay033.png"
description: "Lazarusチャレンジ33日目。Pas2JSでCanvas上の図形をオブジェクトとして管理するホワイトボードを作成しました。TShape継承で矩形・円・線を扱い、ツールパレットと色パレットでドラッグ描画・ドラッグ移動ができます。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day033", "JavaScript", "Canvas", "ホワイトボード", "オートシェイプ", "オブジェクト指向"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでオートシェイプ風ホワイトボードを作成 - Day33

Lazarusチャレンジ33日目です。**Pas2JS** で、Canvas 上で図形（矩形・円・線）を「オブジェクト」として管理し、ドラッグで描画・移動できる **オートシェイプ風ホワイトボード** を作成しました。Pascal の **継承とポリモーフィズム** を活かした設計で、図形を基底クラス `TShape` から派生させ、リストで一括描画・ヒット判定しています。

## 作成したアプリの機能

- **ツールパレット**: 選択・四角・丸・線を切り替え。選択ツールで既存図形をドラッグして移動。
- **図形の追加**: 四角・丸・線を選んでキャンバス上でドラッグすると、プレビュー表示のあとマウスを離すと図形が確定。
- **色パレット**: 10色のスウォッチで色を選択。選択した色が以降に追加する図形に適用され、現在色はプレビュー欄に表示。
- **ヒット判定**: 各図形が `Contains(PX, PY)` で「自分がクリックされたか」を判定。重なりは上（配列の後ろ）から判定。

## 実装のポイント

### 1. クラス設計（継承の活用）

すべての図形の基本となる抽象クラス `TShape` を定義し、矩形・円・線を派生させています。

- **TShape**: 座標 `(X, Y)`、サイズ `(W, H)`、色 `Color`、および `Draw`（描画）と `Contains(PX, PY)`（クリック判定）を持つ。`Draw` は `virtual; abstract;` で派生クラスが実装。
- **TRectangle**: 矩形の `fillRect` / `strokeRect` で描画。`Contains` は基底の「矩形内か」でそのまま利用。
- **TCircle**: 中心と半径から `arc` で描画。`Contains` は中心からの距離で円内か判定（`dx*dx + dy*dy <= r*r`）。
- **TLine**: 始点から終点まで `moveTo` / `lineTo` で描画。`Contains` は線の両端で作る矩形＋余白（HitPad）で近傍クリックを許容。

```pascal
type
  TShape = class
    X, Y, W, H: Integer;
    Color: String;
    constructor Create(AX, AY, AW, AH: Integer; AColor: String);
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); virtual; abstract;
    function Contains(PX, PY: Integer): Boolean; virtual;
  end;

  TRectangle = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
  end;

  TCircle = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
    function Contains(PX, PY: Integer): Boolean; override;
  end;

  TLine = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
    function Contains(PX, PY: Integer): Boolean; override;
  end;

  TToolMode = (tmSelect, tmRect, tmCircle, tmLine);
```

### 2. ポリモーフィズムで一括描画

`Render` では `Shapes` 配列を走査し、`s.Draw(Ctx)` を呼ぶだけです。矩形・円・線の違いを意識せず、各オブジェクトが自分の描画を行います。

```pascal
procedure Render;
var
  s: TShape;
begin
  Ctx.clearRect(0, 0, Canvas.width, Canvas.height);
  for s in Shapes do s.Draw(Ctx);
  if IsDrawing then DrawPreview;
end;
```

### 3. ドラッグ＆ドロップの仕組み

- **MouseDown（選択モード）**: `Shapes` を逆順（重なりが上のものから）に走査し、`Contains(MX, MY)` が True になる最初の図形を `SelectedShape` に保持。オフセット `OffsetX := MX - X`, `OffsetY := MY - Y` を記録し、掴んだ位置を維持したまま移動できるようにします。
- **MouseDown（描画モード）**: ドラッグ開始として `IsDrawing := True`、`DragStartX/Y` を記録。
- **MouseMove**: 描画中は `PreviewW/H` を更新して `DrawPreview` で仮の形を表示。選択中は `SelectedShape` の `X, Y` を更新して `Render`。
- **MouseUp**: 描画中なら最小サイズチェックのうえ、`TRectangle` / `TCircle` / `TLine` を `Shapes` に追加。選択中なら `SelectedShape := nil`。

### 4. pas2js の型名（コンパイル時の注意）

ブラウザ向けにコンパイルする際、次の型名が RTL と一致している必要があります。

- **Canvas 2D コンテキスト**: `TCanvasRenderingContext2D` ではなく **`TJSCanvasRenderingContext2D`**
- **getBoundingClientRect の戻り値**: `TJSClientRect` ではなく **`TJSDOMRect`**

これらに合わせることで `pas2js whiteboard.pas -Tbrowser "-Jirtl.js"` でコンパイルでき、`whiteboard.js` が生成されます。

### 5. ツール・色パレットと DOM

- ツールボタン（選択・四角・丸・線）に `addEventListener('click', ...)` でハンドラを付け、`CurrentTool` を切り替え。選択中ツールは `classList.add('active')` でハイライト。
- 色パレットは親要素 `colorPalette` に 1 つの `click` リスナーを付け、`event.target` が `color-swatch` かつ `data-color` を持っていれば `DefaultColor` を更新し、`UpdateColorPreview` でプレビューを更新。イベント委譲でスウォッチの増減に強い構成にしています。

### 6. 起動タイミング

pas2js でコンパイルしたスクリプトは、DOM が準備できてから実行します。HTML で `DOMContentLoaded` の後に `rtl.run()` を呼びます。

```html
<script src="whiteboard.js"></script>
<script>
  window.addEventListener('DOMContentLoaded', function() {
    if (typeof rtl !== 'undefined') {
      rtl.run();
    } else {
      console.error('Error: pas2js runtime (rtl.js) not found.');
    }
  });
</script>
```

## 完成したコード（抜粋）

### whiteboard.pas（図形クラスとツール・色）

- `TShape` / `TRectangle` / `TCircle` / `TLine` の定義と `Draw`・`Contains` の実装
- `TToolMode` と `CurrentTool`、`IsDrawing`、`DragStartX/Y`、`PreviewW/H`、`DefaultColor`
- `Render`、`DrawPreview`、`MouseDown` / `MouseMove` / `MouseUp`
- `SetToolSelect` などツール切り替え、`UpdatePaletteUI`、`UpdateColorPreview`、`ColorSwatchClick`
- `begin` で Canvas 取得、パレット・色パレットのイベント登録、`Canvas.onmousedown` / `window.onmousemove` / `window.onmouseup` の登録

### index.html（構成）

- タイトル「pas2js オートシェイプ」
- ツールパレット: `#btnSelect`, `#btnRect`, `#btnCircle`, `#btnLine`（`.active` で選択中を表示）
- 色パレット: `.color-swatch` に `data-color` と `style="background-color: ..."`、`#colorPreview`
- `#paintCanvas`（800×600）、説明文、`whiteboard.js` と `DOMContentLoaded` で `rtl.run()`

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js whiteboard.pas -Tbrowser "-Jirtl.js"
```

`whiteboard.js` が生成されます。`index.html` では `rtl.js`（ランタイム）を先に読み込み、その後に `whiteboard.js` を読み込むか、`-Jirtl.js` でランタイムを同梱している場合は `whiteboard.js` のみで構いません。実際のプロジェクトに合わせてスクリプトの読み込み順を調整してください。

## 実行結果

![Pas2JSオートシェイプ](/images/LazarusDay033.png)

ツールで四角・丸・線を選び、色を選んでからキャンバス上でドラッグすると図形が追加されます。選択ツールで図形をクリックしてドラッグすると移動できます。Pascal の継承とポリモーフィズムで、図形の種類を増やしても `Render` とヒット判定のロジックをそのまま使える構成になっています。

## ダウンロード

作成したオートシェイプ風ホワイトボード（HTML / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます：

[day033_whiteboard.zip](/downloads/day033_whiteboard.zip)

図解ツールや簡易CADのように、図形をオブジェクトで管理する処理は Pascal の型とクラス設計がよく合います。次は矢印やテキスト図形の追加、Undo/Redo のリスト管理などに広げるのもおすすめです。

---

*Lazarusチャレンジ Day 33/100*
