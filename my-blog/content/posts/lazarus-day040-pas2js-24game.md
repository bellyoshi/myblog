---
title: "Pas2JSで脳トレ「24Game」を作る - Day40"
date: 2026-02-09T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay040start.png"
description: "Lazarusチャレンジ40日目。4つの数字を＋－×÷して24を作る脳トレ計算パズル「24Game」をPas2JSで作成。Pascalの再帰（バックトラッキング）で「必ず解ける問題」を自動生成し、状態遷移で操作を厳密に管理。JavaScriptでは型が緩く誤差も出やすい計算ロジックを、Pascalで安全に実装しました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day040", "JavaScript", "24Game", "脳トレ", "バックトラッキング", "状態遷移"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで脳トレ「24Game」を作る - Day40

Lazarusチャレンジ40日目です。**4つの数字を「＋－×÷」して24を作る**脳トレ計算パズル「24Game」を Pas2JS でブラウザ向けに作りました。人間がプレイする形式で、数字ボタンと演算子ボタンを順に選んで計算を進め、最後に24になればクリアです。

## ゲームのコンセプト

- **出題**: 1〜9の数字が4つ表示される（必ず24にできる組み合わせだけを出題）
- **操作**: 数字を1つ選ぶ → 演算子（＋－×÷）を選ぶ → 2つ目の数字を選ぶ → 2つが1つの計算結果に置き換わる
- **目標**: 残り1つの数字が **24** になればクリア
- **状態管理**: 「数字選択 → 演算子選択 → 2つ目数字選択」を状態遷移で厳密に制御し、不正な操作を防ぐ

Pascal の再帰（バックトラッキング）が得意な分野で、JavaScript だと型が緩く浮動小数点誤差もバグりやすい計算ロジックを、Pascal で厳密に実装しています。

![24Game 開始画面](/images/LazarusDay040start.png)

## 作成したアプリの機能

- **必ず解ける出題**: `CanSolve` でバックトラッキングし、解けるまでランダムに4数字を生成。解けない問題は出さない
- **状態遷移**: `TInputState`（isSelectFirst / isSelectOp / isSelectSecond / isGameOver / isWin）で入力フェーズを管理
- **四則演算**: 2つ目の数字選択時に計算実行。0除算は防止し、結果で配列を更新（2つを消して1つに）
- **クリア判定**: 残り1つが24のとき誤差範囲（Abs(x - 24) < 0.0001）で判定。Double 型と Epsilon で浮動小数点の扱いを明示
- **UI**: 数字ボタン・演算子ボタン・「新しい問題」ボタン。選択中は `.selected` でハイライト、メッセージで次の操作を案内

クリア時と、24にならなかった場合の画面は次のとおりです。

![24Game クリア](/images/LazarusDay040win.png)

![24Game ゲームオーバー](/images/LazarusDay040gameover.png)

## 開発で行ったこと（ロジック・RTL）

1. **uses の構成**  
   `web`, `sysutils`, `JS`, `Math` を使用。DOM 操作は `web` ユニットで行い、`Abs` や誤差判定に `Math` を利用。

2. **ソルバー（CanSolve）**  
   再帰で「2つの数字を選び、四則のどれかで1つにまとめる」を繰り返し、数字が1つになったときに 24 に一致するかで解の有無を判定。動的配列で残り数字を渡し、解けたら True を返す。

3. **問題生成**  
   `GenerateValidProblem` 相当で、ランダムに4数字を決め、`CanSolve` が True になるまで繰り返し。解ける組み合わせだけをプレイヤーに渡す。

4. **イベントの公開**  
   HTML の `onclick="game.HandleOpClick('+')"` などから呼べるよう、`TJSObject(window)['game']` に `HandleOpClick` と `NewGame` を登録。数字ボタンは Pascal 側で `data-idx` 付きで生成し、クリックで `HandleNumberClick(Index)` を実行。

5. **rtl.run()**  
   Day39 と同様、`game.js` の後に `<script>rtl.run();</script>` を記述し、Pascal の begin からプログラムを開始。

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js game.pas -Tbrowser -Jirtl.js
```

`-Jirtl.js` で RTL が出力に含まれるため、`index.html` から `game.js` を読み込み、`rtl.run()` を呼べばブラウザで動作します。

## HTML / CSS との連携

- **index.html**: タイトル「24Game」、メッセージ用 `#msg`、数字用 `#number-container`、演算子ボタン（＋－×÷）、「新しい問題」ボタン。`game.js` 読み込み後に `rtl.run()` を実行。
- **style.css**: 数字ボタン（`.num-btn`）、演算子ボタン（`.op-btn`）、選択中（`.selected`）、リセット用ボタンのスタイル。脳トレらしく見やすく配置。
- Pascal 側で `UpdateUI` のたびに `#number-container` を再構築し、各数字ボタンに `data-idx` とクリックハンドラを付与。`#msg` に現在の状態に応じた案内文を表示。

## ユニークな点

- **型と誤差**: 24 との一致は `Abs(Numbers[0] - 24) < 0.0001` で判定。JavaScript の `0.1 + 0.2 === 0.3` が false になるような問題を、Pascal の Double と Epsilon で避けている。
- **バックトラッキング**: 出題フィルターとして「解ける問題だけを生成」する部分で、Pascal の再帰がそのまま活きる。
- **状態機械**: 数字→演算子→数字の順序を状態で縛ることで、演算子の連打や不正なクリックで壊れにくい UI にしている。

## ダウンロード

**アプリをブラウザで開く**: [24Game を開く](/apps/day040/)

作成したアプリ（HTML / CSS / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day040_24game.zip](/downloads/day040_24game.zip)

4つの数字と四則演算で24を目指す脳トレとして、そのまま遊べます。ヒント表示や1手戻す（Undo）機能の追加にも、Pascal の配列履歴や状態管理で拡張しやすい構成になっています。

---

*Lazarusチャレンジ Day 40/100*
