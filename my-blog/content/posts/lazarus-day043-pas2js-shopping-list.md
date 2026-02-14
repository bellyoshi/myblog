---
title: "Pas2JSでつくる「お買い物リスト」プログレッシブWebアプリ (PWA) - Day43"
date: 2026-02-12T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay043.png"
description: "Lazarusチャレンジ43日目。LocalStorageを使ってオフラインでも動くチェックリストをPas2JSで作成。TStringListのような感覚でデータを管理し、ブラウザを閉じても消えない実用性がポイント。GeminiでHTML/CSS/PASを取得し、rtl.run()を自分で挿入、Cursorでコンパイル完了。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day043", "PWA", "LocalStorage", "お買い物リスト", "TStringList", "Gemini", "Cursor", "pas2js"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでつくる「お買い物リスト」プログレッシブWebアプリ (PWA) - Day43

Lazarusチャレンジ43日目です。**LocalStorage** を使って、オフラインでも動く「**お買い物リスト**」チェックリストを Pas2JS でブラウザ向けに作りました。**TStringList のような感覚**でデータを管理し、**ブラウザを閉じても消えない**実用性がユニークなポイントです。設計とベースコードは **Gemini** にプロンプトして取得し、HTML/CSS/PAS をコピー＆貼り付け。Gemini の HTML には `rtl.run()` がなかったため自分で挿入し、**Cursor** で pas2js コンパイルを完了させました。

![お買い物リスト PWA 画面](/images/LazarusDay043.png)

## コンセプト

- **LocalStorage**: ブラウザの `window.localStorage` にリストデータを保存。タブを閉じたりオフラインになってもデータが残る
- **TStringList でデータ管理**: Pascal の `TStringList` で「行＝1アイテム」として扱い、`CommaText` で LocalStorage と文字列のやりとり。Delphi/Lazarus 使いにはなじみの感覚で書ける
- **シンプルな PWA 的体験**: 追加・削除・全削除ができ、再読み込みやブラウザ再起動後もリストが復元される

| 機能 | 説明 |
|------|------|
| アイテム追加 | 入力欄に文字を入れて「追加」でリストに追加 |
| 個別削除 | 各項目の「×」でその行だけ削除 |
| 全削除 | 「全削除」で確認ダイアログのあとリストを空に |
| 永続化 | LocalStorage のキー `pas2js_shopping_data` に CommaText で保存 |

## Gemini でやったこと

**Gemini** に次のようなプロンプトを出して、設計とベースコードを取得しました。

- **「pas2jsでつくる『お買い物リスト』プログレッシブWebアプリ (PWA)。LocalStorageを使って、オフラインでも動くチェックリスト。ユニーク点: TStringList のような感覚でデータを管理。ブラウザを閉じても消えない実用性。」**

Gemini からは **HTML / CSS / PAS** のコードが返ってきたので、そのままプロジェクトにコピー＆貼り付けしました。**Gemini の HTML には `<script>rtl.run();</script>` が含まれていなかった**ため、Pas2JS でコンパイルした JS を動かすために、**自分で `</body>` 直前などに `<script>rtl.run();</script>` を挿入**しています。

## Cursor でコンパイル完了

Cursor を起動し、「**pas2js .\shopping.pas -Tbrowser "-Jirtl.js" を実行しコンパイルを完了させる**」ように依頼しました。これで `shopping.pas` から `shopping.js` が生成され、`index.html` から読み込んで `rtl.run()` でプログラムが開始する構成になっています。

## 作成したアプリのポイント（コード抜粋）

- **TStringList と LocalStorage**: `DataList.CommaText := SavedData` で復元、`window.localStorage.setItem(STORAGE_KEY, DataList.CommaText)` で保存。カンマ区切りで1行1アイテムとして扱える
- **イベント**: `AddBtn.onclick`、`ClearBtn.onclick`、`ItemListUI.onclick` で追加・全削除・行ごとの削除（×）を処理
- **再描画**: `RenderList` で `ItemListUI.innerHTML` を空にしてから、`DataList` の内容で `<li>` を生成し直す

## コンパイル方法（Pas2JS）

```bash
pas2js .\shopping.pas -Tbrowser "-Jirtl.js"
```

`static/apps/day043/` など、`shopping.pas` があるディレクトリで実行します。生成された `shopping.js` を `index.html` で読み込み、**`<script>rtl.run();</script>`** でプログラムを開始します。

## 動かない
HTML に **`<script>rtl.run();</script>`** を追加します。geminiの生成したhtmlはこれが抜けています。


## まとめ

- **Gemini**: 「お買い物リスト PWA」「LocalStorage」「TStringList 感覚」「ブラウザを閉じても消えない」とプロンプトし、**HTML / CSS / PAS** のベースを一括取得。コピペで骨格を用意。
- **自分で補った点**: HTML に **`<script>rtl.run();</script>`** を追加。これがないと Pas2JS のエントリが動かない。
- **Cursor**: **pas2js** で `shopping.pas` をコンパイルし、`shopping.js` を生成してコンパイル完了。

「**Pascal の TStringList がブラウザの LocalStorage とつながる**」という形で、実用的なチェックリストが Pas2JS で実現できました。オフラインでもリストが残るので、買い物メモとしてそのまま使えます。
なお、同じデバイスのなかでのストレージになりますので例えば、パソコンで開くのと、タブレットで開いたものは別の結果になり、共有はできません。

## ダウンロード

**アプリをブラウザで開く**: [お買い物リストを開く](/apps/day043/)

作成したアプリ（HTML / CSS / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day043_pas2jsshoppinglist.zip](/downloads/day043_pas2jsshoppinglist.zip)

LocalStorage でデータが残るので、ブラウザを閉じてもリストが消えません。TStringList 感覚でカスタマイズしたい場合は、`shopping.pas` の `DataList` 周りをいじってみてください。

---

*Lazarusチャレンジ Day 43/100*
