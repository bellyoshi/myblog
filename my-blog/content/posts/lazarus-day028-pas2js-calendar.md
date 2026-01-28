---
title: "Pas2JSでカレンダーアプリを作成 - Day28"
date: 2026-01-28T21:00:00+09:00
draft: false
featured_image: "/images/LazarusDay028.png"
description: "Lazarusチャレンジ28日目。Pas2JSを使ってカレンダーアプリを作成しました。年月の切り替え、日付のグリッド表示、sysutils/dateutils を使った日付計算をPascalで実装しました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day028", "JavaScript", "カレンダー"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでカレンダーアプリを作成 - Day28

Lazarusチャレンジ28日目です。昨日に引き続き **Pas2JS** を使って、今度は **カレンダーアプリ** を作成しました。

月の表示と「前の月」「次の月」での切り替え、曜日ヘッダー付きのテーブル表示を、Pascalの `sysutils` と `dateutils` で実装しています。

## 作成したカレンダーアプリの機能

- **年月表示**: 現在表示している年・月をヘッダーに表示
- **前の月 / 次の月**: ボタンで月を切り替え
- **カレンダーグリッド**: その月の日付を曜日付きの表で表示（1日の曜日位置に合わせて配置）

シンプルな月間カレンダーとして、ブラウザ上でそのまま使える形にしました。

## 実装のポイント

### 1. 日付の取得と月の計算

`DecodeDate` で年・月・日を取得し、`EncodeDate` でその月の1日を求めています。`DaysInAMonth` でその月の日数、`DayOfWeek` で1日が何曜日かを取得しています。

```pascal
DecodeDate(CurrentDate, Year, Month, Day);
FirstDayOfMonth := EncodeDate(Year, Month, 1);
DaysInMonth := DaysInAMonth(Year, Month);
StartDay := DayOfWeek(FirstDayOfMonth); // 1:日, 2:月...
```

### 2. 月の切り替え

`dateutils` の `IncMonth` で前月・翌月に移動し、その後 `RenderCalendar` で再描画しています。

```pascal
CurrentDate := IncMonth(CurrentDate, -1);  // 前の月
CurrentDate := IncMonth(CurrentDate, 1);   // 次の月
RenderCalendar;
```

### 3. 曜日名の表示

`FormatSettings.ShortDayNames[i]` で短い曜日名（日・月・火…）を取得し、ヘッダー行に使っています。

```pascal
for i := 1 to 7 do
begin
  Cell := TJSHTMLElement(document.createElement('th'));
  Cell.innerText := FormatSettings.ShortDayNames[i];
  // ...
end;
```

### 4. 描画のクリアと再構築

毎回 `Container.innerHTML := ''` で中身を空にしてから、ヘッダー（ボタン・タイトル）とテーブルを一から作成しています。状態は `CurrentDate` のみで持つ形にしています。

## 完成したコード

### calendar.pas

```pascal
program calendar;

uses
  browserconsole, web, sysutils, dateutils;

var
  CurrentDate: TDateTime;

procedure RenderCalendar;
var
  Container, Header, BtnPrev, BtnNext, Title, Table, Row, Cell: TJSHTMLElement;
  Year, Month, Day: Word;
  FirstDayOfMonth: TDateTime;
  DaysInMonth, StartDay, d, i: Integer;
begin
  DecodeDate(CurrentDate, Year, Month, Day);
  
  // 描画エリアの初期化
  Container := TJSHTMLElement(document.getElementById('calendar-app'));
  if Container = nil then
  begin
    Container := TJSHTMLElement(document.createElement('div'));
    Container.id := 'calendar-app';
    document.body.appendChild(Container);
  end;
  Container.innerHTML := ''; // 以前の描画をクリア

  // --- ヘッダー（年月表示とボタン） ---
  Header := TJSHTMLElement(document.createElement('div'));
  
  BtnPrev := TJSHTMLElement(document.createElement('button'));
  BtnPrev.innerText := '< 前の月';
  BtnPrev.onclick := function(Event: TJSMouseEvent): boolean
  begin
    CurrentDate := IncMonth(CurrentDate, -1);
    RenderCalendar;
    Result := False;
  end;

  Title := TJSHTMLElement(document.createElement('span'));
  Title.innerText := Format(' %d年 %d月 ', [Year, Month]);
  Title.style.setProperty('font-weight', 'bold');

  BtnNext := TJSHTMLElement(document.createElement('button'));
  BtnNext.innerText := '次の月 >';
  BtnNext.onclick := function(Event: TJSMouseEvent): boolean
  begin
    CurrentDate := IncMonth(CurrentDate, 1);
    RenderCalendar;
    Result := False;
  end;

  Header.appendChild(BtnPrev);
  Header.appendChild(Title);
  Header.appendChild(BtnNext);
  Container.appendChild(Header);

  // --- カレンダー本体 ---
  Table := TJSHTMLElement(document.createElement('table'));
  Table.style.setProperty('border-collapse', 'collapse');
  Table.style.setProperty('margin-top', '10px');
  
  FirstDayOfMonth := EncodeDate(Year, Month, 1);
  DaysInMonth := DaysInAMonth(Year, Month);
  StartDay := DayOfWeek(FirstDayOfMonth);

  // 曜日の行
  Row := TJSHTMLElement(document.createElement('tr'));
  for i := 1 to 7 do
  begin
    Cell := TJSHTMLElement(document.createElement('th'));
    Cell.innerText := FormatSettings.ShortDayNames[i];
    Cell.style.setProperty('border', '1px solid #ccc');
    Cell.style.setProperty('padding', '5px');
    Row.appendChild(Cell);
  end;
  Table.appendChild(Row);

  // 日付の行（空白セル + 日付）
  Row := TJSHTMLElement(document.createElement('tr'));
  for i := 1 to StartDay - 1 do
  begin
    Cell := TJSHTMLElement(document.createElement('td'));
    Cell.style.setProperty('border', '1px solid #ccc');
    Row.appendChild(Cell);
  end;

  for d := 1 to DaysInMonth do
  begin
    Cell := TJSHTMLElement(document.createElement('td'));
    Cell.innerText := IntToStr(d);
    Cell.style.setProperty('border', '1px solid #ccc');
    Cell.style.setProperty('padding', '10px');
    Cell.style.setProperty('text-align', 'center');
    
    Row.appendChild(Cell);

    if ((d + StartDay - 1) mod 7 = 0) and (d < DaysInMonth) then
    begin
      Table.appendChild(Row);
      Row := TJSHTMLElement(document.createElement('tr'));
    end;
  end;
  
  Table.appendChild(Row);
  Container.appendChild(Table);
end;

begin
  CurrentDate := Now;
  RenderCalendar;
end.
```

### calendar.html

```html
<html>
  <head>
    <meta charset="utf-8"/>
    <script type="application/javascript" src="calendar.js"></script>
  </head>
  <body>
    <script type="application/javascript">
     rtl.run();
    </script>
  </body>
</html>
```

## コンパイル方法

Day26・Day27と同様、pas2js でブラウザ向けにコンパイルします。

```bash
pas2js .\calendar.pas -Tbrowser "-Jirtl.js"
```

## 実行結果

![Calendar App Screenshot](/images/LazarusDay028.png)

ブラウザで `calendar.html` を開くと、現在の月のカレンダーが表示されます。「前の月」「次の月」で月を切り替えられます。

## ダウンロード

作成したカレンダーアプリは以下のリンクからダウンロードできます：

[day028_calendar.zip](/downloads/day028_calendar.zip)

Pas2JS と `sysutils` / `dateutils` を組み合わせることで、日付処理も含めたWebアプリをPascalだけで書けることが分かりました。次は日付クリックでメモを付けたり、祝日表示などを足してみるのも良さそうです。

---

*Lazarusチャレンジ Day 28/100*
