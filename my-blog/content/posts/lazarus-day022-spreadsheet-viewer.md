---
title: "スプレッドシート作成の試みとビューワー実装 - Day22"
date: 2026-01-22T16:30:00+09:00
draft: false
featured_image: "/images/LazarusDay022.png"
description: "Lazarusチャレンジ22日目。今回はスプレッドシートの手作り実装に挑戦しましたが、Cursorの利用制限により断念。結果としてxlsxファイルを読み込めるビューワーを作成しました。fpspreadsheetライブラリの使用方法などをまとめています。"
tags: ["Lazarus", "GUI", "チャレンジ", "Day022", "Pascal", "fpspreadsheet", "xlsx", "Excel"]
categories: ["技術"]
author: "ブログ管理者"
---

# スプレッドシート作成の試みとビューワー実装 - Day22

Lazarusチャレンジ22日目です。今回は、本来スプレッドシート（表計算ソフト）自体を自作しようと試みましたが、開発途中でCursor（AIエディタ）の利用制限（上限）に引っかかってしまい、手動での作業が必要になりました。

結果として、編集機能までには至りませんでしたが、**Excelファイル（.xlsx）を読み込んで表示するビューワー**として完成させました。

## 今回の目標とその経緯

当初の目標は、セルへの入力や計算機能を持つ簡易的なスプレッドシートアプリケーションの作成でした。しかし、AIアシスタントとの対話中に利用上限に達してしまい、複雑なロジックの実装を継続するのが困難になりました。

そこで目標を切り替え、**既存のExcelファイルを読み込んで表示する**という機能に絞って実装を行いました。

## 実装内容

使用したライブラリは `fpspreadsheet` です。これはFree Pascalでスプレッドシート形式（.ods, .xls, .xlsxなど）を読み書きするための強力なライブラリです。

### ソースコード (Unit1.pas)

以下が今回作成したメインユニットのコードです。

```pascal
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  fpspreadsheet, fpspreadsheetgrid, fpsallformats, fpstypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    MenuItemFile: TMenuItem;
    MenuItemLoad: TMenuItem;
    MenuItemExit: TMenuItem;
    OpenDialog1: TOpenDialog;
    sWorksheetGrid1: TsWorksheetGrid;
    procedure MenuItemLoadClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private

  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


{ --- 読み込み処理 --- }
procedure TForm1.MenuItemLoadClick(Sender: TObject);
begin
  if not OpenDialog1.Execute then
  begin
    Exit;
  end;

  if not FileExists(OpenDialog1.FileName) then
  begin
    ShowMessage('ファイルが見つかりません: ' + OpenDialog1.FileName);
    Exit;
  end;

  try
    // 1. ファイルから読み込む
    sWorksheetGrid1.Workbook.ReadFromFile(OpenDialog1.FileName, sfOOXML);
    ShowMessage('読み込みました');
  except
    on E: Exception do
      ShowMessage('読み込みに失敗しました: ' + E.Message);
  end;
end;

{ --- 終了処理 --- }
procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

{ --- アプリ終了時の処理 --- }
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // 終了時の処理なし
end;

end.
```

## ポイント

### fpspreadsheetの活用

`uses` 節に `fpspreadsheet`, `fpspreadsheetgrid`, `fpsallformats` を追加することで、スプレッドシートの機能を簡単に利用できます。

こちらは使用する前にパッケージのインストールが必要です。
Lazarusのメニューから「パッケージ」→「パッケージマネージャ」で「fpspreadsheet」を検索してインストールしてください。

パッケージをインストールすると、コンパイルが走ります。
![パッケージのインストール](/images/LazarusDay022Package.png)

また、プロジェクトインスペクターで要求パッケージの追加が必要です。

### UI構成

- **TsWorksheetGrid**: スプレッドシートのデータを表示するための専用グリッドコンポーネントです。
- **TOpenDialog**: 読み込むファイルを選択するために使用します。
- **MainMenu**: 「ファイル」メニューから「読み込み」「終了」を選択できるようにしています。

## まとめ

今日はAIの利用制限というトラブルがありましたが、Lazarusには強力なコンポーネントがあるため、短いコードでも実用的なビューワーが作れることが再確認できました。

## ダウンロード

作成したアプリは以下のリンクからダウンロードできます：

[Day022_spread.zip](/downloads/Day022_spread.zip)

次回は、また別のアプリに挑戦します。

---

*Lazarusチャレンジ Day 22/100*
