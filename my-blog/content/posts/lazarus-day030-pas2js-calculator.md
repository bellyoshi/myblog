---
title: "Pas2JSで計算機アプリを作成 - Day30"
date: 2026-01-30T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay030.png"
description: "Lazarusチャレンジ30日目。Pas2JSで数式を入力して計算するブラウザ用計算機を作成しました。evalを使わず、再帰下降構文解析で四則演算とカッコをPascalだけで実装しています。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day030", "JavaScript", "計算機", "構文解析"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで計算機アプリを作成 - Day30

Lazarusチャレンジ30日目です。**Pas2JS** で、数式を入力して計算する **ブラウザ用計算機** を作成しました。JavaScript の `eval` は使わず、**再帰下降構文解析** により四則演算（`+`, `-`, `*`, `/`）とカッコ `()` を Pascal だけで実装しています。

## 作成したアプリの機能

- **数式入力**: テキストボックスに `(10 + 5) * 2` のような数式を入力
- **計算ボタン**: ボタンを押すと計算を実行
- **結果表示**: 計算結果を青文字で表示
- **演算子**: `+`, `-`, `*`, `/` とカッコ `()` に対応（演算子の優先順位も正しく処理）

## 実装のポイント

### 1. DOM へのアクセスとイベント

HTML 側で `id="formula"`, `id="btnCalc"`, `id="result"` を定義し、Pascal 側で `document.getElementById` で取得して型キャストしています。計算ボタンのクリックには `onclick` に `TJSMouseEvent` 型のハンドラを渡します。

```pascal
InputBox := TJSHTMLInputElement(document.getElementById('formula'));
CalcButton := TJSHTMLButtonElement(document.getElementById('btnCalc'));
ResultDiv := TJSElement(document.getElementById('result'));
// ...
CalcButton.onclick := @DoCalculate;
```

### 2. 再帰下降構文解析の構成

計算の優先順位を「式 → 項 → 因数」の3段階で扱います。

- **ParseExpression**（式）: `+`, `-` を処理。その前に **ParseTerm** を呼ぶ。
- **ParseTerm**（項）: `*`, `/` を処理。その前に **ParseFactor** を呼ぶ。
- **ParseFactor**（因数）: 数値または `( 式 )` を処理。カッコの中は再び **ParseExpression** に任せる。

このようにすると、掛け算・割り算が足し算・引き算より先に計算され、カッコも正しく解釈されます。

### 3. 字句の読み進め

`PeekChar`（次の1文字を読むだけ）、`GetChar`（1文字消費して進める）、`SkipWhite`（空白を飛ばす）で入力を先頭から順に解析しています。

```pascal
function PeekChar: Char;
begin
  if Pos <= Length(Expr) then Result := Expr[Pos] else Result := #0;
end;

procedure SkipWhite;
begin
  while (PeekChar = ' ') do GetChar;
end;
```

### 4. eval を使わない理由

`eval` を使うと実装は短くなりますが、任意の JavaScript が実行されるためセキュリティ上のリスクがあります。今回は学習も兼ねて、Pascal だけで数式をパース・計算する方式にしました。

## 完成したコード

### calculator.pas

```pascal
program calculator;

uses
  web, sysutils, js;

var
  InputBox: TJSHTMLInputElement;
  CalcButton: TJSHTMLButtonElement;
  ResultDiv: TJSElement;
  Pos: Integer;
  Expr: string;

// 次の文字を取得
function PeekChar: Char;
begin
  if Pos <= Length(Expr) then Result := Expr[Pos] else Result := #0;
end;

// 1文字進む
function GetChar: Char;
begin
  Result := PeekChar;
  if Result <> #0 then Inc(Pos);
end;

// 空白を飛ばす
procedure SkipWhite;
begin
  while (PeekChar = ' ') do GetChar;
end;

// プロトタイプ宣言（相互参照のため）
function ParseExpression: Double; forward;

// 数値およびカッコの解析
function ParseFactor: Double;
var
  S: string;
begin
  SkipWhite;
  if PeekChar = '(' then
  begin
    GetChar; // '(' を消費
    Result := ParseExpression;
    SkipWhite;
    if PeekChar = ')' then GetChar; // ')' を消費
  end
  else
  begin
    S := '';
    // 数値（小数点含む）を切り出す
    while (PeekChar in ['0'..'9', '.']) do
      S := S + GetChar;
    
    if S = '' then Result := 0 else Result := StrToFloat(S);
  end;
end;

// 掛け算・割り算の解析
function ParseTerm: Double;
var
  Op: Char;
  NextVal: Double;
begin
  Result := ParseFactor;
  SkipWhite;
  while PeekChar in ['*', '/'] do
  begin
    Op := GetChar;
    NextVal := ParseFactor;
    if Op = '*' then Result := Result * NextVal
    else if NextVal <> 0 then Result := Result / NextVal;
    SkipWhite;
  end;
end;

// 足し算・引き算の解析
function ParseExpression: Double;
var
  Op: Char;
  NextVal: Double;
begin
  Result := ParseTerm;
  SkipWhite;
  while PeekChar in ['+', '-'] do
  begin
    Op := GetChar;
    NextVal := ParseTerm;
    if Op = '+' then Result := Result + NextVal
    else Result := Result - NextVal;
    SkipWhite;
  end;
end;

// 計算実行メイン
function DoCalculate(Event: TJSMouseEvent): boolean;
var
  FinalResult: Double;
begin
  Result := False;
  Expr := InputBox.value;
  Pos := 1;
  
  try
    FinalResult := ParseExpression;
    ResultDiv.innerHTML := '結果: ' + FloatToStr(FinalResult);
  except
    ResultDiv.innerHTML := 'エラー: 計算できません';
  end;
end;

begin
  InputBox := TJSHTMLInputElement(document.getElementById('formula'));
  CalcButton := TJSHTMLButtonElement(document.getElementById('btnCalc'));
  ResultDiv := TJSElement(document.getElementById('result'));

  if Assigned(CalcButton) then
    CalcButton.onclick := @DoCalculate;
end.
```

### calculator.html

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="utf-8"/>
    <title>Pas2JS Calculator</title>
    <style>
        body { font-family: sans-serif; padding: 20px; }
        #result { margin-top: 10px; font-weight: bold; color: blue; }
        input { width: 300px; padding: 5px; }
        button { padding: 5px 15px; }
    </style>
</head>
<body>
    <h2>Pas2JS 計算機</h2>
    <input type="text" id="formula" placeholder="例: (10 + 5) * 2">
    <button id="btnCalc">計算</button>
    <div id="result"></div>

    <script src="calculator.js"></script>
    <script>
        window.addEventListener('load', function() {
            rtl.run();
        });
    </script>
</body>
</html>
```

## コンパイル方法

Day26〜29 と同様、pas2js でブラウザ向けにコンパイルします。

```bash
pas2js -Tbrowser calculator.pas
```

`calculator.js` が生成されるので、同じフォルダに `calculator.html` を置き、ブラウザで開いて動作確認します。

## 実行結果

![Calculator Screenshot](/images/LazarusDay030.png)

ブラウザで `calculator.html` を開き、入力欄に `(10 + 5) * 2` などを入力して「計算」ボタンを押すと、結果が表示されます。

## ダウンロード

作成した計算機アプリは以下のリンクからダウンロードできます：

[day030_calculator.zip](/downloads/day030_calculator.zip)

Pas2JS と再帰下降構文解析を組み合わせることで、eval に頼らない安全で拡張しやすい計算機が作れることが分かりました。次は Enter キーで計算や、べき乗・三角関数などの拡張に挑戦するのも良さそうです。

---

*Lazarusチャレンジ Day 30/100*
