---
title: "Lights Outゲームの作成 - Day24"
date: 2026-01-24T19:30:00+09:00
draft: false
featured_image: "/images/LazarusDay024.png"
description: "Lazarusチャレンジ24日目。5x5の盤面すべてのライトを消すパズルゲーム「Lights Out」を作成しました。可解性を保証する初期化アルゴリズムや、動的なコンポーネント生成について解説します。"
tags: ["Lazarus", "GUI", "チャレンジ", "Day024", "Pascal", "Lights Out", "ゲーム", "パズル"]
categories: ["技術"]
author: "ブログ管理者"
---

# Lights Outゲームの作成 - Day24

Lazarusチャレンジ24日目です。今回は、古典的な電子パズルゲーム「**Lights Out**（ライツアウト）」を作成しました。

## ゲームのルール

Lights Outは、5x5のグリッド状に並んだライト（マス）をすべて消灯（OFF）させることを目指すパズルです。

- **操作**: マスをクリックすると、そのマスと上下左右に隣接するマスの状態が反転します（ONならOFF、OFFならON）。
- **目的**: すべてのマスをOFFにすればクリアです。

単純に見えますが、むやみに押すと堂々巡りになり、論理的な思考が求められる奥深いゲームです。

## 実装のポイント

今回はLazarus (Free Pascal) で1フォームのシンプルなアプリケーションとして実装しました。

### 1. 盤面データの管理

盤面の状態は2次元配列で管理します。

```pascal
private
  FLights: array[0..4, 0..4] of Boolean;
```

視覚的な表示には `TPanel` コンポーネントを使用し、これを`FormCreate`イベントで動的に生成しています。これにより、フォームデザイナーで25個のパネルを手作業で配置する手間を省いています。

### 2. 必ず解ける初期配置

Lights Outの重要な性質として、「**ランダムにON/OFF配置を決めると、数学的に解けない配置が存在する**」という点があります。
プレイヤーに不条理な苦痛を与えないよう、初期化処理に一工夫加えました。

1.  まず盤面をすべてOFF（クリア状態）にする。
2.  ランダムな場所をクリック（合法手）する操作を複数回（今回は20回）繰り返す。

この手順で生成された盤面は、逆の手順（押した場所をもう一度押す）を辿れば必ず元に戻せるため、**必ず解けることが保証されます**。

```pascal
procedure TForm1.InitializeGame;
var
  i, rx, ry: Integer;
begin
  Randomize;
  // 全てOFFにする
  for i := 0 to GridSize - 1 do
    for rx := 0 to GridSize - 1 do
      FLights[i, rx] := False;

  // 適当にクリック操作をシミュレートして「必ず解ける」初期盤面を作る
  for i := 1 to 20 do
  begin
    rx := Random(GridSize);
    ry := Random(GridSize);
    ToggleCell(rx, ry);
  end;
  
  UpdateVisuals;
end;
```

### 3. ロジックの実装

マスの反転処理は、範囲チェックを行った上で状態を反転させるシンプルなものです。

```pascal
procedure TForm1.ToggleState(x, y: Integer);
begin
  if (x >= 0) and (x < GridSize) and (y >= 0) and (y < GridSize) then
    FLights[x, y] := not FLights[x, y];
end;

procedure TForm1.ToggleCell(x, y: Integer);
begin
  ToggleState(x, y);     // 自分
  ToggleState(x - 1, y); // 左
  ToggleState(x + 1, y); // 右
  ToggleState(x, y - 1); // 上
  ToggleState(x, y + 1); // 下
end;
```

## 完成したコード (Unit1.pas)

以下がメインユニットの全コードです。

```pascal
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

const
  GridSize = 5;
  CellSize = 60;
  Gap = 5;

type
  { TForm1 }
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
  private
    FLights: array[0..GridSize-1, 0..GridSize-1] of Boolean;
    FPanels: array[0..GridSize-1, 0..GridSize-1] of TPanel;
    FStartBtn: TButton;
    
    procedure PanelClick(Sender: TObject);
    procedure InitializeGame;
    procedure ToggleCell(x, y: Integer);
    procedure ToggleState(x, y: Integer);
    procedure UpdateVisuals;
    function CheckWin: Boolean;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  x, y: Integer;
  P: TPanel;
begin
  // フォーム設定
  Caption := 'Lights Out Game';
  ClientWidth := (CellSize + Gap) * GridSize + Gap;
  ClientHeight := (CellSize + Gap) * GridSize + Gap + 50;
  Position := poScreenCenter;
  Color := clWhite;

  // グリッド生成
  for x := 0 to GridSize - 1 do
  begin
    for y := 0 to GridSize - 1 do
    begin
      P := TPanel.Create(Self);
      P.Parent := Self;
      P.Width := CellSize;
      P.Height := CellSize;
      P.Left := Gap + x * (CellSize + Gap);
      P.Top := Gap + y * (CellSize + Gap);
      P.Tag := x * GridSize + y; // 座標をTagに埋め込む
      P.OnClick := @PanelClick;
      P.BevelOuter := bvNone;
      P.Caption := '';
      P.Color := clSilver;
      
      FPanels[x, y] := P;
    end;
  end;

  // リセットボタン生成
  FStartBtn := TButton.Create(Self);
  FStartBtn.Parent := Self;
  FStartBtn.Caption := 'ゲームリセット';
  FStartBtn.Left := Gap;
  FStartBtn.Top := (CellSize + Gap) * GridSize + 10;
  FStartBtn.Width := ClientWidth - (Gap * 2);
  FStartBtn.Height := 30;
  FStartBtn.OnClick := @ResetButtonClick;

  InitializeGame;
end;

procedure TForm1.InitializeGame;
var
  i, rx, ry: Integer;
begin
  Randomize;
  // 全てOFFにする
  for i := 0 to GridSize - 1 do
    for rx := 0 to GridSize - 1 do
      FLights[i, rx] := False;

  // 適当にクリック操作をシミュレートして「必ず解ける」初期盤面を作る
  for i := 1 to 20 do
  begin
    rx := Random(GridSize);
    ry := Random(GridSize);
    ToggleCell(rx, ry);
  end;
  
  UpdateVisuals;
end;

procedure TForm1.ResetButtonClick(Sender: TObject);
begin
  InitializeGame;
end;

procedure TForm1.PanelClick(Sender: TObject);
var
  idx, x, y: Integer;
begin
  if Sender is TPanel then
  begin
    idx := TPanel(Sender).Tag;
    x := idx div GridSize;
    y := idx mod GridSize;
    
    ToggleCell(x, y);
    UpdateVisuals;
    
    if CheckWin then
    begin
      ShowMessage('クリアおめでとうございます！');
      InitializeGame;
    end;
  end;
end;

procedure TForm1.ToggleState(x, y: Integer);
begin
  if (x >= 0) and (x < GridSize) and (y >= 0) and (y < GridSize) then
    FLights[x, y] := not FLights[x, y];
end;

procedure TForm1.ToggleCell(x, y: Integer);
begin
  ToggleState(x, y);     // 自分
  ToggleState(x - 1, y); // 左
  ToggleState(x + 1, y); // 右
  ToggleState(x, y - 1); // 上
  ToggleState(x, y + 1); // 下
end;

procedure TForm1.UpdateVisuals;
var
  x, y: Integer;
begin
  for x := 0 to GridSize - 1 do
  begin
    for y := 0 to GridSize - 1 do
    begin
      if FLights[x, y] then
      begin
        FPanels[x, y].Color := $0080FFFF; // 明るい色（ON）
        FPanels[x, y].Caption := 'ON';
      end
      else
      begin
        FPanels[x, y].Color := clGray;    // 暗い色（OFF）
        FPanels[x, y].Caption := '';
      end;
    end;
  end;
end;

function TForm1.CheckWin: Boolean;
var
  x, y: Integer;
begin
  Result := True;
  for x := 0 to GridSize - 1 do
    for y := 0 to GridSize - 1 do
      if FLights[x, y] then Exit(False);
end;

end.
```

## 感想

Lazarusの`TPanel`などの標準コンポーネントは`Tag`プロパティを持っているので、そこに座標データ（またはインデックス）を持たせることで、イベントハンドラを共通化しやすくなります。
シンプルなロジックですが、パズルとしても面白く、プログラミングの練習にも最適な題材でした。

## ダウンロード

作成したアプリは以下のリンクからダウンロードできます：

[day024_lightout.zip](/downloads/day024_ligtout.zip)

これでDay24は完了です！

---

*Lazarusチャレンジ Day 24/100*
