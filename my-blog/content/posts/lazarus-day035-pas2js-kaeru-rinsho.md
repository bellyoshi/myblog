---
title: "Pas2JSでかえるのうたを輪唱で再生する - Day35"
date: 2026-02-04T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay035.png"
description: "Lazarusチャレンジ35日目。かえるのうたをWebで再実現し、輪唱にも挑戦しました。Geminiでコードを作成しましたがコンパイルを通すためにCursorで仕上げ。Web Audio API と pas2js で正確なタイミングの輪唱を実現しています。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day035", "JavaScript", "Web Audio API", "かえるのうた", "輪唱"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでかえるのうたを輪唱で再生する - Day35

Lazarusチャレンジ35日目です。今回は **かえるのうた** を再度取り上げ、**Web で再実現** しました。さらに **輪唱** にもチャレンジしています。

Day1 では Lazarus で MIDI ファイルを作成するアプリとして「かえるのうた」を実装しました。今回は **Pas2JS** と **Web Audio API** で、ブラウザ上で直接音を鳴らす形にしています。正確なタイミング制御のために `AudioContext.currentTime` を使い、8拍ずつずらした3パートの輪唱で、かえるのうたが重なって聞こえるようにしました。

## 作成したアプリの機能

- **かえるのうたのメロディー**を Web Audio API のオシレータ（三角波）で再生
- **輪唱**: 1パート目から 8拍（約3.2秒）ずつずらして 2パート目・3パート目を再生。3つのメロディーが重なる輪唱になります
- **エンベロープ**: `linearRampToValueAtTime` と `exponentialRampToValueAtTime` で、音の立ち上がりと減衰を制御し、「ぷつぷつ」したノイズを防ぎつつ自然に聞こえるようにしています
- **音量バランス**: 輪唱で音が重なって大きくなりすぎないよう、各パートの音量を 0.3 / 0.2 / 0.1 と段階的に下げてあります

## 開発の経緯（Gemini → Cursor で仕上げ）

コードは **Gemini** に作成してもらいました。そのままでは pas2js でコンパイルが通らなかったため、**Cursor** で次の2点を修正して仕上げました。

### 1. オシレータの型プロパティ（webaudio の予約名）

webaudio ユニットでは、JavaScript の `type` が Pascal の予約語と衝突するため、プロパティ名が **`type_`** として定義されています。

- **修正前**: `Osc._type := 'triangle';`
- **修正後**: `Osc.type_ := 'triangle';`

### 2. program では initialization が使えない / window の参照

HTML のボタンから `StartRinsho` を呼べるように、グローバルに手続きを登録する必要があります。Gemini のコードでは `initialization` と `TJSWindow.window` を使っていました。

- pas2js の **program** では **initialization** が使えないため、登録処理を **begin .. end** のメイン処理に移動しました。
- グローバルな `window` は **web** ユニットで定義されているので、`TJSWindow.window` ではなく **`window`** をそのまま使うように変更しました。

```pascal
begin
  window['StartRinsho'] := @StartRinsho;
end.
```

HTML 側では `rtl.run()` で Pascal の program を起動し、その中で `window['StartRinsho']` が設定されます。ボタンの `onclick="StartRinsho()"` で輪唱が開始されます。

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js kaeru.pas -Tbrowser "-Jirtl.js"
```

`-Jirtl.js` は RTL 込みの JS を出力するオプションです。引数は **ダブルクォートで囲む** 必要があります（`-Jirtl.js` がファイル名として解釈されないように）。生成された `kaeru.js` と `index.html` を同じフォルダに置けば、ブラウザで「かえるのうた」の輪唱を再生できます。

## 実行結果

「再生開始」ボタンを押すと、かえるのうたが 3 パートで輪唱のように重なって再生されます。ブラウザのオーディオポリシーに従い、ボタンクリックなどのユーザー操作後に再生が開始されます。

## ダウンロード

**アプリをブラウザで開く**: [かえるのうた（輪唱）を開く](/apps/day035/)

作成したアプリ（HTML / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day035_kaeru.zip](/downloads/day035_kaeru.zip)

かえるのうたを Web で鳴らしつつ、輪唱までできるようになりました。次は音色を変えたり、テンポやパート数を変えられるようにするのも面白そうです。

---

*Lazarusチャレンジ Day 35/100*
