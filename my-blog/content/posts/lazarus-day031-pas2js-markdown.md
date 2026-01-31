---
title: "Pas2JSでMarkdownエディタを作成 - Day31"
date: 2026-02-01T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay031.png"
description: "Lazarusチャレンジ31日目。Pas2JSで左にエディタ・右にプレビューを表示する簡易Markdownエディタを作成しました。外部ライブラリなしで、PascalのParseMarkdownで見出し・強調・リスト・リンク・水平線を実装しています。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day031", "JavaScript", "Markdown", "エディタ"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでMarkdownエディタを作成 - Day31

Lazarusチャレンジ31日目です。**Pas2JS** で、左にエディタ・右にプレビューを表示する **簡易Markdownエディタ** を作成しました。marked.js などの外部ライブラリは使わず、**Pascal のロジックのみ**で Markdown を HTML に変換する `ParseMarkdown` を実装しています。

## 作成したアプリの機能

- **左右分割レイアウト**: 左側がテキストエリア（Markdown入力）、右側がプレビュー（HTML表示）
- **リアルタイムプレビュー**: 入力するたびに `oninput` でプレビューを更新
- **対応記法**: 見出し（`#`, `##`）、**太字**（`**`）、リスト（`*` / `-`）、リンク（`[text](url)`）、水平線（`---`）、段落

## 実装のポイント

### 1. DOM へのアクセスとイベント

HTML 側で `id="editor"`（textarea）と `id="preview"`（div）を定義し、Pascal 側で `document.getElementById` で取得します。入力のたびにプレビューを更新するため、`EditorElem.oninput := @DoUpdate` でイベントを紐付けています。

```pascal
EditorElem := TJSHTMLTextAreaElement(document.getElementById('editor'));
PreviewElem := TJSHTMLElement(document.getElementById('preview'));
if Assigned(EditorElem) then
  EditorElem.oninput := @DoUpdate;
```

### 2. 簡易 Markdown パーサー（ParseMarkdown）

改行で分割して1行ずつ処理し、行頭の記号でブロック要素を判定してから、インラインの強調・リンクを正規表現で置換しています。

- **水平線**: `---` の行を `<hr />` に
- **見出し**: `# ` で始まる行を `<h1>`、`## ` を `<h2>` に
- **リスト**: 行頭の `* ` または `- ` を `<li>` に
- **強調**: `**...**` を `TJSRegExp` で `<strong>...</strong>` に
- **リンク**: `[text](url)` を `<a href="url" target="_blank">text</a>` に
- **段落**: 上記のいずれでもない非空行を `<p>...</p>` で囲む

```pascal
Line := TJSString(Line).replace(TJSRegExp.New('\*\*(.*?)\*\*', 'g'), '<strong>$1</strong>');
Line := TJSString(Line).replace(TJSRegExp.New('\[(.*?)\]\((.*?)\)', 'g'), '<a href="$2" target="_blank">$1</a>');
```

### 3. TJSString / TJSRegExp の利用

pas2js では、Pascal の `string` を `TJSString(...)` で JavaScript の String として扱い、`.split()` や `.replace()` が使えます。正規表現は `TJSRegExp.New('パターン', 'g')` で生成し、`$1`, `$2` でキャプチャを参照できます。外部の Markdown ライブラリに頼らずに、Pascal だけで簡易パーサーを書けるポイントです。

### 4. HTML の読み込みタイミング

`editor.js` を head で読み込んでも、body 内の要素はまだ存在しないため、`getElementById` が失敗することがあります。そのため HTML 側では `DOMContentLoaded` で DOM の準備ができてから `rtl.run()` を呼ぶようにしています。

```html
window.addEventListener('DOMContentLoaded', function() {
  if (typeof rtl !== 'undefined') {
    rtl.run();
  }
});
```

### 5. HTML と CSS の分離

レイアウトと見た目は `style.css` にまとめ、HTML は `link rel="stylesheet" href="style.css"` で読み込みます。`.container` で flex を使い、`#editor` と `#preview` を `flex: 1` で左右に均等分割しています。

## 完成したコード

### editor.pas

```pascal
program editor;

{$mode objfpc}{$H+}

uses
  web, sysutils, js;

var
  EditorElem: TJSHTMLTextAreaElement;
  PreviewElem: TJSHTMLElement;

function ParseMarkdown(src: string): string;
var
  Lines: TStringArray;
  i: Integer;
  Line: string;
  InList: Boolean;
begin
  Result := '';
  InList := False;
  Lines := TJSString(src).split(#10); 
  
  for i := 0 to High(Lines) do
  begin
    Line := Lines[i];

    if Line = '---' then
      Line := '<hr />'
    else
    if (Length(Line) > 0) and (Line[1] = '#') then
    begin
      if Copy(Line, 1, 2) = '# ' then Line := '<h1>' + Copy(Line, 3, Length(Line)) + '</h1>'
      else if Copy(Line, 1, 3) = '## ' then Line := '<h2>' + Copy(Line, 4, Length(Line)) + '</h2>';
    end
    else
    if (Length(Line) >= 2) and ((Line[1] = '*') or (Line[1] = '-')) and (Line[2] = ' ') then
      Line := '<li>' + Copy(Line, 3, Length(Line)) + '</li>';

    Line := TJSString(Line).replace(TJSRegExp.New('\*\*(.*?)\*\*', 'g'), '<strong>$1</strong>');
    Line := TJSString(Line).replace(TJSRegExp.New('\[(.*?)\]\((.*?)\)', 'g'), '<a href="$2" target="_blank">$1</a>');

    if (Pos('<', Line) <> 1) and (Trim(Line) <> '') then
      Line := '<p>' + Line + '</p>';

    Result := Result + Line + #10;
  end;
end;

function DoUpdate(Event: TJSEvent): boolean;
begin
  if Assigned(EditorElem) and Assigned(PreviewElem) then
    PreviewElem.innerHTML := ParseMarkdown(EditorElem.value);
  Result := True;
end;

begin
  EditorElem := TJSHTMLTextAreaElement(document.getElementById('editor'));
  PreviewElem := TJSHTMLElement(document.getElementById('preview'));

  if Assigned(EditorElem) then 
    EditorElem.oninput := @DoUpdate;
end.
```

### editor.html

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="utf-8">
    <title>Pas2JS Markdown Editor</title>
    <link rel="stylesheet" href="style.css">
    <script src="editor.js"></script>
</head>
<body>
    <div class="container">
        <textarea id="editor" placeholder="Markdownを入力..."></textarea>
        <div id="preview"></div>
    </div>

    <script>
        window.addEventListener('DOMContentLoaded', function() {
            if (typeof rtl !== 'undefined') {
                rtl.run();
            }
        });
    </script>
</body>
</html>
```

### style.css（抜粋）

- `body` / `.container`: マージン・パディングゼロ、flex で `100vw` × `100vh` を確保
- `#editor`, `#preview`: `flex: 1` で左右50%ずつ、`padding: 25px`、`overflow-y: auto`
- `#editor`: 等幅フォント、リサイズなし、右ボーダーで区切り
- `#preview`: 見出しの下線（`h1` / `h2`）、`strong` の色指定、`code` の背景など

## コンパイル方法

Day26〜30 と同様、pas2js でブラウザ向けにコンパイルします。

```bash
pas2js -Tbrowser editor.pas
```

`editor.js` が生成されるので、同じフォルダに `editor.html` と `style.css` を置き、ブラウザで `editor.html` を開いて動作確認します。

## 実行結果

![Markdown Editor Screenshot](/images/LazarusDay031.png)

左側に Markdown を入力すると、右側にリアルタイムでプレビューが表示されます。見出し・太字・リスト・リンク・水平線が正しく反映されることを確認できます。

## ダウンロード

作成した Markdown エディタ（HTML / CSS / ソース）は以下のリンクからダウンロードできます：

[day031_markdown_editor.zip](/downloads/day031_markdown_editor.zip)

外部ライブラリを使わず Pascal だけで簡易 Markdown パーサーを実装することで、依存関係を減らしつつ、TJSString と TJSRegExp の使い方に慣れる良い練習になりました。次は LocalStorage で内容を保存したり、コードブロックのシンタックスハイライトに挑戦するのも良さそうです。

---

*Lazarusチャレンジ Day 31/100*
