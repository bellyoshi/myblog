---
title: "Pas2JSでつくる「ピクセルアート・エディター」16x16 - Day44"
date: 2026-02-13T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay044.png"
description: "Lazarusチャレンジ44日目。HTML5 Canvasを16x16グリッドで制御するピクセルアートエディターをPas2JSで作成。LocalStorageで自動保存、PNGダウンロード対応。Geminiで設計・コード取得、CursorでTypeError（null参照）とクリアボタン未接続を修正して完成。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day044", "Canvas", "ピクセルアート", "LocalStorage", "Gemini", "Cursor", "pas2js"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでつくる「ピクセルアート・エディター」16x16 - Day44

Lazarusチャレンジ44日目です。**HTML5 の &lt;canvas&gt;** を、Pascal の二次元配列として制御する **16×16 のピクセルアート・エディター**を Pas2JS で作りました。**LocalStorage で自動保存**、**PNG ダウンロード**に対応。設計とベースコードは **Gemini** にプロンプトして取得し、実行時に出た **TypeError（null 参照）** と **クリアボタンが効かない**問題を **Cursor** で修正して完成させました。

![ピクセルアート・エディター 画面](/images/LazarusDay044.png)

## コンセプト

- **16×16 グリッド**: Canvas の座標を計算し、クリックした位置に対応する配列要素を更新。色は CSS の `#RRGGBB` 文字列で管理し、`<input type="color">` とそのままやり取り
- **LocalStorage で常時保存**: 描画のたびに `AutoSave` で `pixel_data` に保存。ブラウザを閉じても絵が残る
- **ダウンロード**: Canvas の `toDataURL('image/png')` で PNG 画像として保存
- **レトロ風 UI**: ダークテーマ・グリッド線・`image-rendering: pixelated` でドットがくっきり表示

| 機能 | 説明 |
|------|------|
| 描画 | キャンバスをクリックで選択色を塗る |
| 色選択 | カラーピッカーで色を変更 |
| クリア | グリッドをすべて黒に戻す |
| 保存 (PNG) | 現在の絵を PNG でダウンロード |
| 自動保存 | LocalStorage に随時保存、再読み込みで復元 |

## Gemini でやったこと

**Gemini** に「**pas2js でつくる、レトロゲーム風ピクセルアート・エディター。HTML5 Canvas を二次元配列で制御。16×16 に限定。保存→ダウンロード、途中保存→LocalStorage で常に保存**」とプロンプトし、設計とコード例をもらいました。

- **データ構造**: `TColorArr = array[0..15, 0..15] of string` で CSS 色文字列を保持
- **Render**: 配列を `fillRect` で Canvas に描画し、グリッド線を `strokeRect` で描画
- **OnCanvasClick**: `offsetX / CELL_SIZE` でインデックスを算出し、`Grid[ix][iy]` を更新して `Render` と `AutoSave` を実行
- **HTML/CSS**: Gemini から受け取った HTML と CSS を分離した構成（`index.html` + `style.css`）にしてもらい、レトロなツール風のスタイルを適用

このベースをそのままプロジェクトにコピーし、pas2js でコンパイルしてブラウザで実行しました。

## Cursor で直したこと（TypeError とクリア）

実行すると **TypeError** が続出し、**クリアボタンを押しても何も起きない**状態でした。Cursor にエラーメッセージと「該当箇所を確認して修正して」と依頼して対応しました。

### 1. TypeError: Cannot read properties of null (reading '0' など)

**原因**

- **localStorage から復元した Grid** が不正（古い形式・壊れたデータで行が null や欠けている）のとき、`Grid[ix][iy]` で `Grid[ix]` が null になり null 参照が発生
- その例外が `createSafeCallback` 内でキャッチされ、そのまま再スローされていた

**対応**

- **Init（localStorage 読み込み後）**: パース結果が 16×16 の配列か検証。各行が配列で 16 要素あるか確認し、不足・null は `"#000000"` で埋める正規化を追加
- **OnCanvasClick**: `Grid` と `Grid[ix]` が null でない場合だけ `Grid[ix][iy]` に書き込むガードを追加
- **Render**: `Grid[x][y]` を参照する前に `Grid[x]` と `Grid[x][y]` の null チェックをし、null のときは `"#000000"` を使用
- **TColorArr$clone（AutoSave 用）**: 行が 16 要素未満のときは `"#000000"` で 16 要素になるよう補完

これで、古い or 壊れた `pixel_data` が localStorage に残っていてもクラッシュしなくなりました。まだエラーが出る場合は、ブラウザの「アプリケーション」→「ローカルストレージ」で `pixel_data` を削除してから再読み込みするとよいです。

### 2. クリアを押してもクリアされない

**原因**: 「クリア」ボタン（`#btnClear`）にクリック時の処理が紐づいていませんでした。

**対応**

- **pixel_editor.js**: `OnClear` を追加（グリッドをすべて `#000000` にし、`Render()` と `AutoSave()` を実行）。`Init` 内で `btnClear.onclick` に `OnClear` を割り当て
- **pixel_editor.pas**: `OnClear` 手続きを追加し、`Init` 内で `btnClear` に `@OnClear` を割り当て

これで「クリア」を押すとキャンバスが黒で塗りつぶされ、その状態が LocalStorage にも保存されます。

## 作成したアプリのポイント（コード抜粋）

- **座標→インデックス**: `ix := Floor(Event.OffsetX / CELL_SIZE);` でクリック位置を 0..15 のインデックスに変換
- **色のやりとり**: `Grid[ix, iy] := Picker.value` でカラーピッカーの値をそのまま格納。Cardinal とビット演算を使わず文字列のまま扱うことで pas2js と HTML の連携がシンプルに
- **自動保存**: `OnCanvasClick` の最後で `AutoSave` を呼び、`TJSJSON.stringify(Grid)` で LocalStorage に保存
- **ダウンロード**: `<a>` 要素を生成し、`href := Canvas.toDataURL('image/png')`、`download := 'pixel-art.png'` を設定して `click` でダウンロード

## コンパイル方法（Pas2JS）

```bash
pas2js pixel_editor.pas -Tbrowser "-Jirtl.js"
```

`pixel_editor.pas` があるディレクトリで実行します。生成された `pixel_editor.js` を `index.html` で読み込み、**`<script>rtl.run();</script>`** でプログラムを開始します（Gemini の HTML に rtl.run が無い場合は手動で追加）。

## まとめ

- **Gemini**: 「16×16 ピクセルアート・エディター」「Canvas」「LocalStorage 自動保存」「PNG ダウンロード」とプロンプトし、**HTML / CSS / Pascal** の設計とコードを取得。コピペで骨格を用意。
- **Cursor**: 実行時の **TypeError（localStorage 由来の不正な Grid による null 参照）** を、Init での検証・正規化と OnCanvasClick / Render の null チェックで解消。**クリアボタンに OnClear を紐づけて**クリア機能を有効化。

Pascal の二次元配列がそのまま Canvas のピクセルと対応する形で、1 日でレトロ風ピクセルエディターが完成しました。LocalStorage で状態が残るので、ブラウザを閉じても続きから描けます。

## ダウンロード

**アプリをブラウザで開く**: [ピクセルアート・エディターを開く](/apps/day044/)

作成したアプリ（HTML / CSS / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day044_pixel.zip](/downloads/day044_pixel.zip)

---

*Lazarusチャレンジ Day 44/100*
