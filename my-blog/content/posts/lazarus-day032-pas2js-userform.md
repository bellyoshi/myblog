---
title: "Pas2JSで型安全なユーザー登録フォームを作成 - Day32"
date: 2026-02-01T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay032.png"
description: "Lazarusチャレンジ32日目。Pas2JSで範囲型・列挙型・集合型を活かした型安全なユーザー登録フォームを作成しました。PascalのレコードにDOMの値をバインドし、ValidateUserで厳密なバリデーションを行います。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day032", "JavaScript", "フォーム", "バリデーション", "型安全"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで型安全なユーザー登録フォームを作成 - Day32

Lazarusチャレンジ32日目です。**Pas2JS** で、Pascal の **範囲型・列挙型・集合型** を活かした **型安全なユーザー登録フォーム** を作成しました。ユーザーが入力したデータを Pascal の `record` にバインドし、型定義に基づいた厳密なバリデーション（`ValidateUser`）を行い、エラー時は HTML 上にメッセージを表示します。

## 作成したアプリの機能

- **ユーザー名**: 3文字以上で入力（バリデーションでチェック）
- **年齢**: 18〜120歳の範囲型（`TAgeRange = 18..120`）で検証
- **興味のある分野**: テクノロジー・アート・スポーツ・音楽から複数選択（集合型 `TInterests`）
- **送信ボタン**: クリックで Pascal 側のバリデーションを実行し、成功時はアラート、失敗時はエラーメッセージを表示

## 実装のポイント

### 1. Pascal の型定義（UserForm ユニット）

フォームの「器」となる型を定義します。

- **範囲型** `TAgeRange = 18..120` … 年齢の有効範囲を型で表現
- **列挙型** `TInterest = (itTech, itArt, itSports, itMusic)` … 興味の種類を型安全に
- **集合型** `TInterests = set of TInterest` … 複数選択を Pascal の Set で管理
- **レコード** `TUserRegistration` … ユーザー名・年齢・興味をまとめて保持
- **バリデーション結果** `TValidationResult` … `IsValid` と `ErrorMessage` を返す

```pascal
type
  TAgeRange = 18..120;
  TInterest = (itTech, itArt, itSports, itMusic);
  TInterests = set of TInterest;

  TUserRegistration = record
    UserName: string;
    Age: Integer;
    Interests: TInterests;
  end;

  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
  end;
```

### 2. バリデーション関数 ValidateUser

`TUserRegistration` を受け取り、ユーザー名の長さ・年齢の範囲・興味が1つ以上選択されているかをチェックし、`TValidationResult` を返します。Pascal の `in` 演算子で `Data.Age in [Low(TAgeRange)..High(TAgeRange)]` のように範囲チェックができます。

```pascal
function ValidateUser(const Data: TUserRegistration): TValidationResult;
begin
  Result.IsValid := False;
  if Length(Data.UserName) < 3 then
  begin
    Result.ErrorMessage := 'ユーザー名は3文字以上で入力してください。';
    Exit;
  end;
  if not (Data.Age in [Low(TAgeRange)..High(TAgeRange)]) then
  begin
    Result.ErrorMessage := '年齢は18歳から120歳の間で入力してください。';
    Exit;
  end;
  if Data.Interests = [] then
  begin
    Result.ErrorMessage := '興味のある分野を少なくとも1つ選択してください。';
    Exit;
  end;
  Result.IsValid := True;
  Result.ErrorMessage := '';
end;
```

### 3. DOM との連携（メインプログラム）

HTML の `getElementById` で入力要素を取得し、値を Pascal のレコードにバインドします。チェックボックスは `querySelectorAll('input[name="interest"]:checked')` で取得し、`value` が `itTech` などの文字列なので、if 文で列挙型にマッピングして `Include(Data.Interests, itTech)` で集合に追加します。その後 `ValidateUser(Data)` を呼び、結果に応じてエラー表示要素の `innerText` と `display` を更新するか、`window.alert` で成功を表示します。

```pascal
Data.UserName := THTMLInputElement(Doc.getElementById('userName')).value;
Data.Age := StrToIntDef(THTMLInputElement(Doc.getElementById('age')).value, 0);
Data.Interests := [];
CBs := Doc.querySelectorAll('input[name="interest"]:checked');
for I := 0 to CBs.length - 1 do
begin
  CB := THTMLInputElement(CBs[I]);
  if CB.value = 'itTech' then Include(Data.Interests, itTech);
  if CB.value = 'itArt' then Include(Data.Interests, itArt);
  // ... itSports, itMusic も同様
end;
Result := ValidateUser(Data);
```

### 4. HTML と CSS の設計

フォームは `novalidate` にし、ブラウザ標準のバリデーションではなく Pascal 側のロジックを優先します。エラーメッセージ用の `div` には `aria-live="polite"` を付けてアクセシビリティに対応。チェックボックスの `value`（`itTech`, `itArt` など）を Pascal の列挙型と一致させておくと、マッピングが簡単になります。CSS では `.error-msg` でエラー表示、`.input-error` で入力欄の強調が可能です。

### 5. 起動タイミング

pas2js でコンパイルしたスクリプトは、DOM が準備できてから実行する必要があります。HTML 側で `DOMContentLoaded` の後に `rtl.run()` を呼びます。また `rtl.js` を先に読み込み、その後に `project.js`（コンパイル結果）を読み込みます。

```html
<script src="rtl.js"></script>
<script src="project.js"></script>
<script>
  window.addEventListener('DOMContentLoaded', function() {
    if (typeof rtl !== 'undefined') {
      rtl.run();
    }
  });
</script>
```

## 完成したコード

### UserForm.pas（ユニット）

```pascal
unit UserForm;

interface

type
  TAgeRange = 18..120;
  TInterest = (itTech, itArt, itSports, itMusic);
  TInterests = set of TInterest;

  TUserRegistration = record
    UserName: string;
    Age: Integer;
    Interests: TInterests;
  end;

  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
  end;

function ValidateUser(const Data: TUserRegistration): TValidationResult;

implementation

function ValidateUser(const Data: TUserRegistration): TValidationResult;
begin
  Result.IsValid := False;
  if Length(Data.UserName) < 3 then
  begin
    Result.ErrorMessage := 'ユーザー名は3文字以上で入力してください。';
    Exit;
  end;
  if not (Data.Age in [Low(TAgeRange)..High(TAgeRange)]) then
  begin
    Result.ErrorMessage := '年齢は18歳から120歳の間で入力してください。';
    Exit;
  end;
  if Data.Interests = [] then
  begin
    Result.ErrorMessage := '興味のある分野を少なくとも1つ選択してください。';
    Exit;
  end;
  Result.IsValid := True;
  Result.ErrorMessage := '';
end;

end.
```

### UserFormProject.pas（メイン）

```pascal
program UserFormProject;

uses
  browserhtml, sysutils, UserForm;

procedure OnSubmitClick(Event: TEventListenerEvent);
var
  Data: TUserRegistration;
  Res: TValidationResult;
  Doc: TDocument;
  ErrorDiv: TJSHTMLElement;
  I: Integer;
  CBs: TNodeList;
  CB: THTMLInputElement;
begin
  Doc := window.document;
  ErrorDiv := TJSHTMLElement(Doc.getElementById('errorMessage'));

  Data.UserName := THTMLInputElement(Doc.getElementById('userName')).value;
  Data.Age := StrToIntDef(THTMLInputElement(Doc.getElementById('age')).value, 0);

  Data.Interests := [];
  CBs := Doc.querySelectorAll('input[name="interest"]:checked');
  for I := 0 to CBs.length - 1 do
  begin
    CB := THTMLInputElement(CBs[I]);
    if CB.value = 'itTech' then Include(Data.Interests, itTech);
    if CB.value = 'itArt' then Include(Data.Interests, itArt);
    if CB.value = 'itSports' then Include(Data.Interests, itSports);
    if CB.value = 'itMusic' then Include(Data.Interests, itMusic);
  end;

  Res := ValidateUser(Data);

  if Res.IsValid then
  begin
    ErrorDiv.style.setProperty('display', 'none');
    window.alert('登録成功！型安全なデータが準備できました。');
  end
  else
  begin
    ErrorDiv.innerText := Res.ErrorMessage;
    ErrorDiv.style.setProperty('display', 'block');
  end;
end;

begin
  window.document.getElementById('submitBtn').addEventListener('click', @OnSubmitClick);
end.
```

### index.html（抜粋）

- `form` に `novalidate` を指定
- `id="userName"`, `id="age"`, `name="interest"` のチェックボックス（value: itTech, itArt, itSports, itMusic）, `id="errorMessage"`, `id="submitBtn"` を配置
- `rtl.js` → `project.js` の順で読み込み、`DOMContentLoaded` で `rtl.run()` を実行

### style.css（抜粋）

- `.form-container`: 白背景・角丸・シャドウでフォームを囲む
- `.form-group`, `.checkbox-group`: ラベルと入力のレイアウト
- `.error-msg`: エラー時のみ表示（`display: none` → `block`）、赤系の背景とボーダー
- `.input-error`: 不正な入力欄の強調（必要に応じて Pascal 側でクラスを付与）

## コンパイル方法

UserForm ユニットとメインプログラムを pas2js でブラウザ向けにコンパイルします。

```bash
pas2js -Jc -vw UserFormProject.pas
```

生成された `UserFormProject.js` を HTML 側で `project.js` として読み込むか、ファイル名を合わせてください。`rtl.js` は pas2js のランタイムなので、同じディレクトリに配置するか、CDN から取得します。

## 実行結果

![型安全ユーザー登録フォーム](/images/LazarusDay032.png)

ユーザー名を3文字以上、年齢を18〜120の範囲で入力し、興味を1つ以上選択して「データを検証して登録」ボタンを押すと、バリデーションが通り登録成功のアラートが表示されます。条件を満たさない場合は、エラーメッセージがフォーム上に表示されます。

## ダウンロード

**アプリをブラウザで開く**: [ユーザー登録フォームを開く](/apps/day032/UserForm1.html)

作成した型安全ユーザー登録フォーム（HTML / CSS / Pascal ソース）は以下のリンクからダウンロードできます：

[day032_UserForm1.zip](/downloads/day032_UserForm1.zip)

Pascal の範囲型・集合型をフォームバリデーションに活かすことで、「入力＝型」の保証ができ、ビジネスロジックを型定義に集約できます。バックエンドも Delphi / Free Pascal であれば、同じ UserForm ユニットを共有して DRY にすることも可能です。次はリアルタイムバリデーション（入力のたびにチェック）や、エラー時に該当入力欄にクラスを付与する演出を追加するのも良さそうです。

---

*Lazarusチャレンジ Day 32/100*
