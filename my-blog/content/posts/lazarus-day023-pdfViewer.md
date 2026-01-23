---
title: "PDFビューワーの作成とAIクレジット枯渇との戦い - Day23"
date: 2026-01-23T17:00:00+09:00
draft: false
featured_image: "/images/LazarusDay023.png"
description: "Lazarusチャレンジ23日目。PDFビューワーの作成に挑戦。AIクレジットの枯渇により、手書きコーディングと過去資産の流用でPDFiumライブラリを使ったビューワーを実装しました。ラッパークラスの設計などを解説します。"
tags: ["Lazarus", "GUI", "チャレンジ", "Day023", "Pascal", "PDF", "PDFium", "ビューワー"]
categories: ["技術"]
author: "ブログ管理者"
---

# PDFビューワーの作成とAIクレジット枯渇との戦い - Day23

Lazarusチャレンジ23日目です。今回は、**PDFファイルを表示するビューワー**の作成に挑戦しました。

しかし、今回はこれまでと少し事情が違います。開発の相棒である **Cursor Pro（AIエディタ）の月間クレジットがついに底をつきかけてしまいました。** そのため、AIに頼り切った開発から一転、ほとんどのコードを**手書きと過去の自作コードの流用**で実装するという、原点回帰的な開発となりました。

## 今回の目標と制約

目標は、PDFファイルを読み込み、ページをめくれるシンプルなビューワーを作ることです。

- **目標**:
  - PDFファイルを開いて表示できる
  - 「次へ」「前へ」ボタンでページを移動できる
  - 現在のページ番号と総ページ数を表示する
- **制約**:
  - AI（Cursor）の使用を最小限に抑える
  - 過去に作成したコード資産を積極的に再利用する

## 実装の核：PDFiumライブラリ

PDFのレンダリングは非常に複雑なため、ゼロから作るのは現実的ではありません。そこで、GoogleがメンテナンスしているオープンソースのPDFレンダリングライブラリ **PDFium** を利用することにしました。

LazarusからPDFiumを利用するには、`pdfium.dll`というダイナミックリンクライブラリ（DLL）が必要です。このDLLをアプリケーションの実行ファイルと同じフォルダに配置し、Pascalコードからその関数を呼び出すことで、PDFの機能を利用します。

### DLLの準備

`pdfium.dll`は、公式のGitHubリポジトリなどから、自分の環境（Windows 64bitなど）に合ったものをダウンロードして配置する必要があります。

## 実装戦略：ラッパークラスによる抽象化

PDFiumのAPIはC言語スタイルであり、そのまま使うのはPascalのオブジェクト指向に馴染みません。そこで、過去のプロジェクトの経験を活かし、APIを使いやすくするための**ラッパークラス**を複数作成しました。AIに頼れない今、このような構造化されたコード資産が非常に役立ちます。

### 主なユニット構成

- **`PdfiumLib.pas`**: `pdfium.dll`からエクスポートされている関数を直接宣言するユニット。

  ```pascal
  // pdfium.dllの関数をPascalから使えるように宣言
  procedure FPDF_InitLibrary(); cdecl; external PDFiumDll;
  function FPDF_LoadDocument(file_path: FPDF_STRING; ...): FPDF_DOCUMENT; cdecl; external PDFiumDll;
  // ...など
  ```

- **`PdfDocument.pas`**: PDFドキュメント全体を管理する`TPdfDocument`クラス。ファイルの読み込みやクローズ、ページ数の取得などを担当します。

- **`PdfPage.pas`**: 個々のページを管理する`TPdfPage`クラス。ページの幅や高さを取得します。

- **`PdfRenderer.pas`**: PDFのページをLazarusの`TBitmap`オブジェクトに描画（レンダリング）する手続きをまとめたユニット。

- **`PdfViewer.pas`**: UIとやり取りする高レベルな`TPdfViewer`クラス。現在のページインデックスを管理し、ページ移動のロジック（`Next`, `Previous`）などを持ちます。

このように機能を分割することで、メインフォームのコード（`Unit1.pas`）は非常にシンプルになります。

## UIの実装 (Unit1.pas)

メインフォームでは、`TPdfViewer`クラスを利用してPDFの表示と操作を行います。

```pascal
unit Unit1;

interface

uses
  ..., PdfViewer;

type
  TForm1 = class(TForm)
    // ... UIコンポーネント
  private
    FPdfViewer: TPdfViewer; // ビューワーのインスタンス
    procedure LoadPdfFile(const FileName: string);
    procedure UpdatePage;
    // ...
  public

  end;

implementation

// ...

procedure TForm1.LoadPdfFile(const FileName: string);
begin
  try
    if Assigned(FPdfViewer) then
      FPdfViewer.Free;

    // 新しいPDFファイルでビューワーインスタンスを作成
    FPdfViewer := TPdfViewer.Create(FileName);

    UpdatePage; // 最初のページを表示
    Caption := 'PDF Viewer - ' + ExtractFileName(FileName);
  except
    on E: Exception do
      ShowMessage('PDFファイルの読み込みに失敗しました: ' + E.Message);
  end;
end;

procedure TForm1.UpdatePage;
var
  Bitmap: TBitmap;
begin
  if not Assigned(FPdfViewer) then
  begin
    Image1.Picture.Clear;
    lblPageInfo.Caption := 'ページ 0 / 0';
    Exit;
  end;

  // ビューワーから現在のページのビットマップを取得
  Bitmap := FPdfViewer.GetBitmap(Panel1.ClientWidth, Panel1.ClientHeight);
  Image1.Picture.Assign(Bitmap); // TImageに表示
  Bitmap.Free;

  // ページ情報を更新
  lblPageInfo.Caption := Format('ページ %d / %d', [FPdfViewer.PageIndex + 1, FPdfViewer.PageCount]);

  // ボタンの有効/無効を更新
  btnPrevious.Enabled := FPdfViewer.CanPrevious;
  btnNext.Enabled := FPdfViewer.CanNext;
end;

procedure TForm1.btnNextClick(Sender: TObject);
begin
  if Assigned(FPdfViewer) then
  begin
    FPdfViewer.Next; // 次のページへ
    UpdatePage;      // 表示を更新
  end;
end;

// ... btnPreviousClickも同様

end.
```

UI側のコードは、`TPdfViewer`オブジェクトに「次のページを見せて」「今のページを画像にして」と指示するだけで済み、PDFiumの複雑な詳細を知る必要がありません。

## まとめ

AIクレジットの枯渇という予期せぬ制約により、今回は手書きでのコーディングがメインとなりました。しかし、そのおかげで**過去に作成したコードの再利用性**や、**複雑なライブラリを使いやすく抽象化するラッパークラスの重要性**を再認識することができました。

AIは強力なツールですが、それに頼れなくなったとき、最後に自分を助けるのは基礎的なコーディング能力と、これまでに積み上げてきた設計の知識やコード資産なのだと痛感した一日でした。

!完成したPDFビューワー

## ダウンロード

作成したアプリは以下のリンクからダウンロードできます：


[day010_SimpleEditor.zip](/downloads/day023_pdfViewer.zip)
※実行するには、`pdfium.dll`を同じフォルダに配置する必要があります。

次回のDay24では、また別のアプリに挑戦します。


---

*Lazarusチャレンジ Day 23/100*
