---
title: "Pas2JSでカラー表示アプリを作成 - Day29"
date: 2026-01-29T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay029.png"
description: "Lazarusチャレンジ29日目。Pas2JSでテキスト入力に応じて背景色が変わるカラー表示アプリを作成しました。inputイベント、setAttribute、CSS transitionをPascalから扱う方法をまとめます。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day029", "JavaScript", "カラー"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでカラー表示アプリを作成 - Day29

Lazarusチャレンジ29日目です。**Pas2JS** で、入力欄に色（`#RRGGBB` や色名）を入力すると、下の四角の背景色がリアルタイムで変わる **カラー表示アプリ** を作成しました。

## 作成したアプリの機能

- **テキスト入力**: `#RRGGBB`（例: `#ff0000`）や `red` などの色名を入力
- **リアルタイム反映**: 入力に合わせて下の四角の背景色が即座に変わる（`input` イベント使用）
- **見た目**: 中央寄せレイアウト、200×200px のプレビュー領域、枠線付き
- **おまけ**: `transition` で色の変化をスムーズにアニメーション

## 実装のポイント

### 1. ページ読み込み後にDOMを構築

ブラウザでDOMが準備できてから要素を作るため、`window.addEventListener('load', ...)` で `DocumentLoaded` を呼び出しています。

```pascal
begin
  window.addEventListener('load', @DocumentLoaded);
end.
```

### 2. input 要素の type と placeholder

Pas2JS では `TJSHTMLInputElement` の `type` を直接代入するとエラーになることがあるため、`setAttribute` で指定しています。

```pascal
InputBox := TJSHTMLInputElement(document.createElement('input'));
InputBox.setAttribute('type', 'text');
InputBox.setAttribute('placeholder', '#RRGGBB or color name');
```

### 3. 入力のリアルタイム反映

`addEventListener('input', @HandleInput)` で、入力のたびに `HandleInput` が呼ばれ、`ColorDisplay` の背景色を `InputBox.value` に更新しています。

```pascal
procedure HandleInput(Event: TJSEvent);
begin
  ColorDisplay.style.setProperty('background-color', InputBox.value);
end;
// ...
InputBox.addEventListener('input', @HandleInput);
```

### 4. スムーズな色変化（CSS transition）

`style.setProperty('transition', 'background-color 0.3s')` で、背景色の変更が 0.3 秒でアニメーションするようにしています。

## 完成したコード

### color.pas

```pascal
program color;

uses
  web, sysutils;

var
  InputBox: TJSHTMLInputElement;
  ColorDisplay: TJSHTMLElement;

procedure HandleInput(Event: TJSEvent);
begin
  // 入力された値を背景色に反映
  ColorDisplay.style.setProperty('background-color', InputBox.value);
end;

procedure DocumentLoaded(Event: TJSEvent);
var
  Container: TJSHTMLElement;
begin
  Container := TJSHTMLElement(document.createElement('div'));
  Container.style.setProperty('text-align', 'center');
  Container.style.setProperty('margin-top', '50px');
  document.body.appendChild(Container);

  InputBox := TJSHTMLInputElement(document.createElement('input'));
  // Error回避: setAttribute を使用して type を指定
  InputBox.setAttribute('type', 'text');
  InputBox.setAttribute('placeholder', '#RRGGBB or color name');
  
  InputBox.style.setProperty('padding', '10px');
  InputBox.style.setProperty('font-size', '18px');
  Container.appendChild(InputBox);

  ColorDisplay := TJSHTMLElement(document.createElement('div'));
  ColorDisplay.style.setProperty('width', '200px');
  ColorDisplay.style.setProperty('height', '200px');
  ColorDisplay.style.setProperty('margin', '20px auto');
  ColorDisplay.style.setProperty('border', '2px solid #333');
  ColorDisplay.style.setProperty('transition', 'background-color 0.3s'); // おまけ：アニメーション
  ColorDisplay.style.setProperty('background-color', '#ccc');
  Container.appendChild(ColorDisplay);

  InputBox.addEventListener('input', @HandleInput);
end;

begin
  window.addEventListener('load', @DocumentLoaded);
end.
```

### color.html

```html
<html>
  <head>
    <meta charset="utf-8"/>
    <script type="application/javascript" src="color.js"></script>
  </head>
  <body>
    <script type="application/javascript">
     rtl.run();
    </script>
  </body>
</html>
```

## コンパイル方法

Day26〜28と同様、pas2js でブラウザ向けにコンパイルします。

```bash
pas2js .\color.pas -Tbrowser "-Jirtl.js"
```

## 実行結果

![Color App Screenshot](/images/LazarusDay029.png)

ブラウザで `color.html` を開き、入力欄に `#ff0000` や `blue`、`rgb(100,200,100)` などを入力すると、下の四角の背景色がリアルタイムで変わります。

## ダウンロード

作成したカラー表示アプリは以下のリンクからダウンロードできます：

[day029_color.zip](/downloads/day029_color.zip)

Pas2JS で `input` イベントと `style.setProperty` を組み合わせるだけで、シンプルなカラー表示ツールが作れることが分かりました。次はカラーピッカー（スライダー）やクリップボードコピーなどを足してみるのも良さそうです。

---

*Lazarusチャレンジ Day 29/100*
