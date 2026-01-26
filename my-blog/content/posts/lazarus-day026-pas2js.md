---
title: "Pas2JSを試してみる - Day26"
date: 2026-01-26T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay026.png"
description: "Lazarusチャレンジ26日目。PascalをJavaScriptに変換する「Pas2JS」を試してみました。Lazarus IDEからの利用で躓いた点や、コマンドラインでのコンパイル方法、-Jirtl.jsパラメータの罠について解説します。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day026", "JavaScript"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSを試してみる - Day26

Lazarusチャレンジ26日目です。今回は、PascalのコードをJavaScriptに変換してブラウザで動作させる **Pas2JS** を試してみました。

Webアプリケーションを作る上で、使い慣れたPascal言語が使えるのは大きな魅力です。しかし、導入にはいくつかのハードルがありました。

## 2つのはまりポイント

今回遭遇した主な問題は以下の2点です。

1. **Lazarus IDEからではコンパイルできなかった**
2. **pas2jsのパラメータ `-Jirtl.js` がファイル名として解釈されてしまう**

これらをどのように解決したか、順を追って説明します。

## 1. Lazarus IDEでの試行錯誤

最初はLazarus IDEの機能を使って開発しようとしました。

`プロジェクト` -> `新規プロジェクト` -> `Web browser Application` (A pas2js program running in the browser) を選択しました。

![Project Template](/images/LazarusDay026_Project.png)
![Project Template](/images/LazarusDay026_Project2.png)

しかし、プロジェクトをコンパイルしようとすると以下のエラーが発生しました。

```text
プロジェクトをコンパイル, OS: browser, CPU: ecmascript5対象：
コード6を終了、エラー: 2
project1.lpr(5,5) Error: can't find unit "System"
Fatal: Compilation aborted
```

Lazarusのバージョンは4.4です。Windows環境とLinux環境で試しましたが、どちらも同じエラーが発生しました。IDE環境ではうまくいっていないようでしたので、手動でセットアップすることにしました。

## 2. Pas2JSの手動セットアップ

以下のサイトからコンパイラをダウンロードしました。

[https://getpas2js.freepascal.org/](https://getpas2js.freepascal.org/)

今回は `Windows(intel)` 版を選択しました。

### インストール手順

1. ダウンロードしたファイルを展開します。
2. `C:\Lazarus\pas2js` フォルダを作成し、その中に展開したファイルをコピーしました。
3. `C:\Lazarus\pas2js\bin` の中に `pas2js.exe` があることを確認します。
4. 環境変数を修正して `C:\Lazarus\pas2js\bin` へのパスを通しました。

## 3. コマンドラインからのコンパイルと引数の罠

簡単な `hello.pas` と `hello.html` を作成し、コマンドラインからコンパイルを試みました。

最初は、サイトのチュートリアル通り以下のコマンドを実行しました：

```bash
pas2js -Jc -Jirtl.js -Tbrowser .\hello.pas
```

すると、以下のエラーが発生しました。

```text
Fatal: parameter .\hello.pas: Only one Pascal file is supported, but got "C:\Users\bellm\source\repos\bellyoshi\Daily-Lazarus-Apps\day026_pas2js\.js" and ".\hello.pas".
```

どうやら `-Jirtl.js` というオプションが正しく認識されず、ファイル名の一部として誤解釈されているようです。

### 解決策

オプションの引数をダブルクォーテーションで囲むことで解決しました。

```bash
pas2js .\hello.pas -Tbrowser "-Jirtl.js"
```

これにより、無事にコンパイルが通りました。

```text
Pas2JS Compiler version 3.2.0 [2025/08/01] for Win32 i386
Copyright (c) 2025 Free Pascal team.
Info: 12172 lines in 6 files compiled, 0.1 secs
```

## 作成したコード

動作確認に使用したコードは以下の通りです。

### hello.pas

```pascal
program hello;
uses
  Web;

begin
  document.Writeln('Hello, world!');
end.
```

### hello.html

```html
<html>
  <head>
    <meta charset="utf-8"/>
    <script type="application/javascript" src="hello.js"></script>
  </head>
  <body>
    <script type="application/javascript">
     rtl.run();
    </script>
  </body>
</html>
```

ブラウザで `hello.html` を開くと、「Hello, world!」と表示され、Pascalで書かれたコードがJavaScriptとして実行されていることが確認できました。

## ダウンロード

作成したサンプルファイルは以下からダウンロードできます：

[day026_pas2jshello.zip](/downloads/day026_pas2jshello.zip)

Pas2JSを使えば、フロントエンドのロジックもPascalで記述できるため、Lazarusユーザーにとっては非常に強力なツールになるのでしょうか。WebAssemblyを試してみたいのですがpas2jsが基礎知識になるようです。まずは今回、比較的簡単なpas2jsを試してみたところ、思ったより複雑な部分が多く、なかなかのいばらの道です。

---

*Lazarusチャレンジ Day 26/100*
