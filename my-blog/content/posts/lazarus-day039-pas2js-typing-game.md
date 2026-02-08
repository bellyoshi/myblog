---
title: "Pas2JSでブラウザ動くPascal予約語タイピングゲームを作る - Day39"
date: 2026-02-08T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay039.png"
description: "Lazarusチャレンジ39日目。流れてくるPascalの予約語（begin, end, procedureなど）をタイプしてEnterで送信する「打鍵速度タイピング」をPas2JSで作成。Turbo Pascal／Delphi／Free Pascalの予約語と事前定義識別子をキーワードにし、実行時にkeywords.txtをfetchで読み込むので再コンパイル不要でキーワードを差し替え可能にしました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day039", "JavaScript", "タイピングゲーム", "Canvas", "予約語", "fetch"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでブラウザ動くPascal予約語タイピングゲームを作る - Day39

Lazarusチャレンジ39日目です。**流れてくるPascalの予約語**（begin, end, procedure など）をタイプして [Enter] で送信する「打鍵速度タイピング」を Pas2JS でブラウザ向けに作りました。Pascal学習者向けに、キーワードを打ちながら言語に慣れ親しめる構成にしています。

## ゲームのコンセプト

- 画面上を**単語が左から右へ流れる**
- 表示されているいずれかの単語と**一致する文字列を入力**して Enter で送信
- 一致した単語は消え、その**文字数がスコア**に加算
- 入力内容は**キャンバス上**と **CURRENT INPUT** エリアの両方にリアルタイム表示

Pascal は大文字小文字を区別しないので、`BEGIN` と打っても `begin` を消せるようにするなど、言語の特性を体感できるようにするのも一案です。

## 作成したアプリの機能

- **Canvas 描画**: 背景・流れる単語・入力中テキスト（黄色）を毎フレーム描画
- **入力判定**: Backspace で末尾1文字削除、Enter で先頭から順に単語一致判定とスコア加算、通常キーで1文字追加
- **キーワード約106語**: Turbo Pascal / Delphi / Free Pascal の予約語と事前定義識別子を網羅（absolute, and, array, begin, class, procedure, ...）
- **キーワードの外部ファイル化**: 実行時に `keywords.txt` を fetch で読み込むため、**再コンパイルなし**でキーワードを差し替え可能。取得失敗時は `keywords.inc` の組み込みリストにフォールバック

## 開発で行ったこと（コンパイル・RTL）

現行の pas2js RTL には `browser` ユニットがないため、次のように修正しました。

1. **uses の修正**  
   `browser` を `js` に変更し、`TStringDynArray` 用に `types` を追加。  
   - `uses js, sysutils, types, web;`

2. **Keywords の初期化**  
   `TStringDynArray` はクラスではないため、配列リテラルで初期化。  
   - `Keywords := ['begin', 'end', 'procedure', ...];`  
   または `keywords.inc` を `{$I keywords.inc}` でインクルード。

3. **実行時キーワード読み込み**  
   起動時に `fetch('keywords.txt')` で1行1単語のテキストを取得し、パースしてからゲーム開始。50ms 間隔のタイマーで `window._keywordsReady` を確認し、完了後に `StartGame` を呼ぶ構成にしました。

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js .\typing_game.pas -Tbrowser "-Jirtl.js"
```

`-Jirtl.js` により RTL が出力に含まれるので、`index.html` から生成された `typing_game.js` を読み込めばブラウザで動作します。`keywords.txt` を使う場合は、`file://` ではなく簡易 HTTP サーバー（例: `npx serve .` や Python の `http.server`）で配信して開いてください。

## HTML / CSS との連携

- **index.html**: ゲーム用 Canvas、スコア表示、CURRENT INPUT 用の `#current-word`、説明文を配置。`typing_game.js` を読み込み。
- **style.css**: ダークテーマ・モノスペースフォントで、Canvas と入力エリアを視認しやすくスタイル分離。
- Pascal 側で `document.getElementById('gameCanvas')` で Canvas を取得し、`HandleKeyDown` 内で `#current-word` に `UserInput` を反映して入力内容を表示。

## キーワードの管理

- **keywords.inc**: コンパイル時に `{$I keywords.inc}` で取り込む配列要素（'単語', ...）の並び。編集後は pas2js で再コンパイルが必要。
- **keywords.txt**: 1行1単語。実行時に fetch で読み込むため、**このファイルを編集してブラウザを再読み込みするだけで**キーワードを変更できます。再コンパイルは不要です。
キーワードのためだけにコンパイルするのは面倒なのでtxtだけを採用しました。

## rtlを実行する
スクリプトはsrcにjsファイルを指定するだけでなく、以下のように呼び出さなければ
pascalのbeinからのプログラムが始まりません。
```
<script>
  rtl.run();
</script>
```

## ダウンロード

**アプリをブラウザで開く**: [Pascal Keyword Typer を開く](/apps/day039/)

作成したアプリ（HTML / CSS / Pascal ソース・keywords.inc・keywords.txt・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day039_pas2jsTypingGame.zip](/downloads/day039_pas2jsTypingGame.zip)

Pascal の予約語を流しながらタイプするので、文法を覚えつつタイピング練習ができます。キーワードを自分用に増減して楽しんでみてください。

---

*Lazarusチャレンジ Day 39/100*
