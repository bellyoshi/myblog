---
title: "Pas2JSで簡易インタープリタをブラウザで動かす - Day34"
date: 2026-02-03T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay034.png"
description: "Lazarusチャレンジ34日目。Pas2JSで簡易インタープリタを作成し、ブラウザ上でPRINT・変数・代入・IF/ELSE・WHILE/WENDを実行できるようにしました。再帰下降構文解析で四則演算の優先順位と括弧を正しく扱います。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day034", "JavaScript", "インタープリタ", "再帰下降", "構文解析", "PRINT", "WHILE", "IF"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで簡易インタープリタをブラウザで動かす - Day34

Lazarusチャレンジ34日目です。**Pas2JS** で、ブラウザ上で動く **簡易インタープリタ** を作成しました。PRINT・変数代入・IF/ELSE・WHILE/WEND をサポートし、式は **再帰下降構文解析** で四則演算の優先順位（`*`/`/` が `+`/`-` より優先、括弧対応）を正しく評価します。Pascal でトークナイザとパーサを実装し、DOM のテキストエリアとボタンから「Run」で実行できる構成にしています。

## 作成したアプリの機能

- **PRINT 文**: 式の値を数値として出力（変数・四則演算・括弧付き式を引数に可能）
- **変数**: 代入（`x = 5`）と式内での参照。未定義変数は 0 として扱う
- **IF 文**: 式が 0 でなければ直後の 1 文を実行、0 ならスキップ。**ELSE** 対応（ELSE を消費し、THEN/ELSE のどちらか一方だけ実行）
- **WHILE / WEND**: 式が 0 でない間、本体（複数文）を繰り返し実行。ネストした WHILE や IF にも対応
- **式**: 再帰下降で `+` `-` `*` `/`、括弧、単項 `+`/`-`、数値・変数を評価

## 実装のポイント

### 1. ブラウザ向けコンパイルと onclick の型

pas2js でブラウザ向けにコンパイルする際、DOM の `onclick` には **手続き型ではなく関数型**（戻り値あり）が必要です。`OnRunClick` を `procedure` から `function OnRunClick(Event: TJSMouseEvent): Boolean` に変更し、先頭で `Result := True` を代入することでコンパイルエラーを解消しています。

```bash
pas2js SimpleInterpreter.pas -Tbrowser "-Jirtl.js"
```

### 2. 再帰下降構文解析（四則演算の優先順位）

式の評価は次の文法で再帰下降パーサを実装しています。

- **expression** = term ( (`+` | `-`) term )*
- **term** = factor ( (`*` | `/`) factor )*
- **factor** = `(` expression `)` | 単項 `+`/`-` factor | 数値 | 変数

1トークン先読み（`FLookAhead`、`PeekToken`）を導入し、トークンを消費する `FetchToken` と、先読みがあればそれを返す `GetToken` に分離。`ParseExpression` → `ParseTerm` → `ParseFactor` の流れで、例えば次のように評価されます。

- `2 + 3 * 4` → 14（`*` が先）
- `(2 + 3) * 4` → 20（括弧が最優先）
- `-1 + 2` → 1（単項マイナス）

### 3. 変数の仕組み

- **格納**: `TInterpreter` の `FVariables: TStringList` で「名前=値」を文字列で保持。値は参照時に `StrToFloatDef(..., 0)` で数値に変換
- **代入**: 文が `PRINT`/`IF`/`WHILE` 以外の 1 トークンのとき「変数名」とみなし、`**=` を 1 トークン消費してから** 右辺を `EvaluateExpression` で評価して代入
- **参照**: `ParseFactor` 内で、数値・括弧・単項演算子以外のトークンは変数名として `FVariables.Values[T]` を参照。未定義時は 0
- **代入で `=` を消費しないバグ** があったため、右辺が `=` から始まって 0 になっていた問題を、「代入と判断したら `=` を消費してから右辺を評価」するよう修正しました

### 4. IF 文の仕様

- **書式**: `IF` の次に式 1 つ、その直後に 1 文（THEN は省略可能）。続けて `ELSE` と 1 文を書ける
- **意味**: 式が 0 でなければ THEN 側の 1 文を実行し、`ELSE` があれば ELSE 側の 1 文を**スキップ**。式が 0 なら THEN 側をスキップし、`ELSE` があれば `ELSE` を消費して ELSE 側の 1 文を**実行**
- 条件は「式が 0 かどうか」のみ（比較演算子は未実装）

### 5. WHILE 文の仕様

- **書式**: `WHILE` の後に式、続けて複数文、最後に `WEND`
- **意味**: 式が 0 でない間、本体を繰り返し実行。`SkipUntilWEND` で `WEND` までスキップする際、内側の `WHILE` があればその条件と本体もスキップしてから対応する `WEND` まで進む
- `DoWhileLoop` 内でも IF/ELSE を同じ仕様で処理

### 6. PRINT 文について

PRINT の引数は `EvaluateExpression` で評価されるため、変数・式のどちらも指定できます。表示は **数値のみ**（文字列リテラルは未対応）です。

## サンプルプログラム（index.html のテキストエリア例）

```
n = 3
WHILE n
PRINT n
n = n - 1
WEND
PRINT 99
x = 1
IF x
PRINT 1
ELSE
PRINT 0
PRINT 100
```

**期待される出力例**: `3` → `2` → `1` → `99` → `1` → `100`（WHILE で 3,2,1 と 99、IF で 1 が表示され、ELSE はスキップ、最後に 100）

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js SimpleInterpreter.pas -Tbrowser "-Jirtl.js"
```

`-Jirtl.js` で RTL 込みの JS が生成されます。`index.html` ではスクリプトを読み込み、DOM 準備後に実行する形にします。

## 実行結果

Pas2JS簡易インタープリタ

テキストエリアにサンプルを入力し「Run」で実行すると、PRINT の結果が出力欄に表示されます。再帰下降で四則の優先順位と括弧が正しく動き、変数・IF/ELSE・WHILE/WEND で簡単なプログラムを試せます。

## ダウンロード

**アプリをブラウザで開く**: [簡易インタープリタを開く](/apps/day034/)

作成した簡易インタープリタ（HTML / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day034_SimpleInterpreter.zip](/downloads/day034_SimpleInterpreter.zip)

Pascal でトークナイザ・再帰下降パーサ・文の実行を一通り実装する良い練習になります。次は REM コメント、比較演算子付きの IF、FOR 文などに拡張するのもおすすめです。

---

*Lazarusチャレンジ Day 34/100*