---
title: "Pas2JSでTodoアプリを作成 - Day27"
date: 2026-01-27T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay027pas2jsTodo.png"
description: "Lazarusチャレンジ27日目。Pas2JSを使ってTodoアプリを作成しました。DOM操作、イベントハンドリング、チェックボックスの状態管理など、Webアプリケーションの基本的な機能をPascalで実装しました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day027", "JavaScript", "Todo"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでTodoアプリを作成 - Day27

Lazarusチャレンジ27日目です。昨日に引き続き **Pas2JS** を使って、今度は実用的なTodoアプリを作成しました。

Pas2JSを使えば、Pascalで書いたコードがJavaScriptに変換され、ブラウザで動作します。今回は、DOM操作やイベントハンドリングなど、Webアプリケーションの基本的な機能を実装してみました。

## 作成したTodoアプリの機能

- **タスクの追加**: 入力フィールドにタスクを入力してEnterキーまたは「追加」ボタンで追加
- **タスクの完了**: チェックボックスをクリックすると、タスクに取り消し線が表示される
- **タスクの削除**: 「削除」ボタンでタスクを削除

シンプルながら、Webアプリケーションの基本的な機能を網羅しています。

## 実装のポイント

### 1. DOM要素の作成と操作

Pas2JSでは、`TJSHTMLElement` や `TJSHTMLInputElement` などの型を使ってDOM要素を操作します。

```pascal
InputText := TJSHTMLInputElement(document.createElement('input'));
InputText.placeholder := 'タスクを入力してEnter...';
```

### 2. イベントハンドリング

イベントハンドラの登録は `TJSObject` 経由で行います。特に注意が必要なのは、キーイベントの処理です。

```pascal
function HandleKeyPress(Event: TJSEvent): boolean;
begin
  Result := True;
  // EventをTJSObjectとして扱い、'keyCode' または 'key' にアクセス
  if (TJSObject(Event)['keyCode'] = 13) or (TJSObject(Event)['key'] = 'Enter') then
    AddTodo(Event);
end;
```

`keyCode` や `key` プロパティにアクセスするには、`TJSObject` にキャストする必要があります。

### 3. 動的な要素の追加

タスクを追加する際、チェックボックス、テキスト、削除ボタンを動的に作成してリストに追加します。

```pascal
ListItem := TJSHTMLElement(document.createElement('li'));
CheckBox := TJSHTMLInputElement(document.createElement('input'));
TJSObject(CheckBox)['type'] := 'checkbox';

SpanText := TJSHTMLElement(document.createElement('span'));
SpanText.innerText := ' ' + TaskText + ' ';

DeleteBtn := TJSHTMLElement(document.createElement('button'));
DeleteBtn.innerText := '削除';
```

### 4. クロージャを使ったイベントハンドリング

チェックボックスや削除ボタンのイベントハンドラでは、クロージャを使って各要素の状態を管理します。

```pascal
TJSObject(CheckBox)['onchange'] := function(E: TJSEvent): boolean
  begin
    if CheckBox.checked then
      SpanText.style.setProperty('text-decoration', 'line-through')
    else
      SpanText.style.setProperty('text-decoration', 'none');
    Result := True;
  end;
```

## 完成したコード

### todo.pas

```pascal
program todo;

uses
  Web, sysutils, JS;

var
  InputText: TJSHTMLInputElement;
  AddButton: TJSHTMLElement;
  TodoList: TJSHTMLElement;

function AddTodo(Event: TJSEvent): boolean;
var
  ListItem, SpanText, DeleteBtn: TJSHTMLElement;
  CheckBox: TJSHTMLInputElement;
  TaskText: string;
begin
  Result := True;
  TaskText := InputText.Value;
  if TaskText = '' then Exit;

  ListItem := TJSHTMLElement(document.createElement('li'));

  CheckBox := TJSHTMLInputElement(document.createElement('input'));
  TJSObject(CheckBox)['type'] := 'checkbox';
  
  SpanText := TJSHTMLElement(document.createElement('span'));
  SpanText.innerText := ' ' + TaskText + ' ';

  DeleteBtn := TJSHTMLElement(document.createElement('button'));
  DeleteBtn.innerText := '削除';

  TJSObject(CheckBox)['onchange'] := function(E: TJSEvent): boolean
    begin
      if CheckBox.checked then
        SpanText.style.setProperty('text-decoration', 'line-through')
      else
        SpanText.style.setProperty('text-decoration', 'none');
      Result := True;
    end;

  TJSObject(DeleteBtn)['onclick'] := function(E: TJSEvent): boolean
    begin
      ListItem.remove;
      Result := True;
    end;

  ListItem.appendChild(CheckBox);
  ListItem.appendChild(SpanText);
  ListItem.appendChild(DeleteBtn);
  TodoList.appendChild(ListItem);

  InputText.Value := '';
  InputText.focus;
end;

// キー入力を判定する関数（TJSObjectでkeyCodeを取得）
function HandleKeyPress(Event: TJSEvent): boolean;
begin
  Result := True;
  // EventをTJSObjectとして扱い、'keyCode' または 'key' にアクセス
  if (TJSObject(Event)['keyCode'] = 13) or (TJSObject(Event)['key'] = 'Enter') then
    AddTodo(Event);
end;

begin
  document.body.insertAdjacentHTML('afterbegin', '<h1>Pascal Todo App</h1>');

  InputText := TJSHTMLInputElement(document.createElement('input'));
  InputText.placeholder := 'タスクを入力してEnter...';
  
  // イベント登録もTJSObject経由で確実に
  TJSObject(InputText)['onkeypress'] := @HandleKeyPress;
  document.body.appendChild(InputText);

  AddButton := TJSHTMLElement(document.createElement('button'));
  AddButton.innerText := '追加';
  TJSObject(AddButton)['onclick'] := @AddTodo;
  document.body.appendChild(AddButton);

  TodoList := TJSHTMLElement(document.createElement('ul'));
  document.body.appendChild(TodoList);
end.
```

### todo.html

```html
<html>
<head>
  <meta charset="utf-8" />
  <script type="application/javascript" src="todo.js"></script>
</head>
<body>
  <script type="application/javascript">
    rtl.run();
  </script>
</body>
</html>
```

## コンパイル方法

day026で学んだ通り、以下のコマンドでコンパイルします。

```bash
pas2js .\todo.pas -Tbrowser "-Jirtl.js"
```

## 実行結果

![Todo App Screenshot](/images/LazarusDay027pas2jsTodo.png)

ブラウザで `todo.html` を開くと、Pascalで書かれたTodoアプリが動作します。タスクの追加、完了、削除がすべて正常に機能します。

## ダウンロード

作成したTodoアプリは以下のリンクからダウンロードできます：

[day027_todo.zip](/downloads/day027_todo.zip)

Pas2JSを使うことで、Pascalの知識をそのままWebアプリケーション開発に活かせることが分かりました。DOM操作やイベントハンドリングなど、JavaScriptで書くべき部分もPascalで記述できるのは大きな魅力ですかね？

---

*Lazarusチャレンジ Day 27/100*
