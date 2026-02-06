---
title: "Pas2JSで経過日数カウンター（何日目か表示）を作る - Day36"
date: 2026-02-06T17:00:00+09:00
draft: false
featured_image: "/images/LazarusDay036.png"
description: "Lazarusチャレンジ36日目。2月になってチャレンジ何日目かわからなくなったので、開始日を選ぶと「今日は○日目」と表示する経過日数カウンターをPas2JSで作成。StrToDateのpas2js仕様（第2引数はTFormatSettings）に合わせてYYYY-MM-DDを手動パースする修正をCursorで行いました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day036", "JavaScript", "日付", "経過日数", "カウンター"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで経過日数カウンター（何日目か表示）を作る - Day36

Lazarusチャレンジ36日目です。1月の時は日にちがチャレンジ日でしたので問題なかったのですが、
2月に入り、**チャレンジ何日目かがわからなくなる**ことがあったので、 
 **開始日を選ぶと「今日は○日目」** と表示する **経過日数カウンター** を Pas2JS で作りました。
このアプリにより一日さぼってことが判明しました。
本日実行すると「今日は37日目」と表示されたけれど、本投稿は day036 です。
本日中にアプリをもう一つ挑戦しましょう。

## 作成したアプリの機能

- **開始日の選択**: `<input type="date">` でチャレンジ開始日を選ぶ（初期値は今年の1月1日）
- **経過日数の表示**: 「今日は開始日から **○日目**」と表示。開始日を1日目として、今日まで何日経過したかを計算
- **日付変更時の再計算**: 開始日を変更すると即座に表示が更新される

## 開発でハマった点（pas2js の StrToDate）

日付文字列（`YYYY-MM-DD`）を `TDateTime` に変換する際、最初は次のように書いていました。

```pascal
StrToDate(StartDateInput.Value, 'YYYY-MM-DD')
```

**pas2js** では `StrToDate` の第2引数は **TFormatSettings 型** であり、フォーマット文字列を渡す仕様ではありません。このためコンパイルエラーになります。

- **対応**: TFormatSettingsについていろいろ調査するより
入力が常に `YYYY-MM-DD` 形式なら、**手動でパース**するのが確実です。`Copy` と `StrToInt` で年・月・日を取り出し、`EncodeDate(y, m, d)` で `TDateTime` に変換するように変更しました。
もちろんCursor君にお任せなんですけどね。

```pascal
S := StartDateInput.Value;
y := StrToInt(Copy(S, 1, 4));
m := StrToInt(Copy(S, 6, 2));
d := StrToInt(Copy(S, 9, 2));
StartDate := EncodeDate(y, m, d);
```

`ScanDateTime`（dateutils）も pas2js では第2引数に `TFormatSettings` を要求するため、固定フォーマットの場合は手動パースで十分です。

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js .\project1.pas -Tbrowser "-Jirtl.js"
```

`-Jirtl.js` は RTL 込みの JS を出力するオプションで、**ダブルクォートで囲む**必要があります。同じディレクトリに `project1.js` が生成されるので、`index.html` からそのスクリプトを読み込み、`rtl.run()` で実行すればブラウザで動作確認できます。

## 実行結果

開始日（例: チャレンジ開始日や今年の1月1日）を選ぶと、「今日は開始日から **○日目**」と表示されます。日付入力の変更で即座に再計算されます。不正な日付の場合は `--` と表示されます。

## ダウンロード

**アプリをブラウザで開く**: [経過日数カウンターを開く](/apps/day036/)

作成したアプリ（HTML / Pascal ソース・コンパイル済み JS / CSS）は以下のリンクからダウンロードできます。

[day036_project1.zip](/downloads/day036_project1.zip)

チャレンジ何日目かをすぐ確認できるので、これからも活用していきます。
さらにアプリを拡張するなら終了日を指定して残り日数を表示するなどもよさそうです。

---

*Lazarusチャレンジ Day 36/100*
