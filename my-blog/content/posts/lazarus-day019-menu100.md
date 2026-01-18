---
title: "Lazarusアプリ用ランチャーの作成 - Day19"
date: 2026-01-19T06:00:00+09:00
draft: false
featured_image: "/images/LazarusDay019.png"
description: "Lazarusチャレンジ19日目。たくさんのアプリができたので、それらを管理・起動するためのランチャーアプリを作成しました。JSONファイルでアプリ情報を管理し、ListViewで一覧表示します。"
tags: ["Lazarus", "GUI", "チャレンジ", "Day019", "Pascal", "ランチャー", "メニュー", "JSON", "ListView", "アプリ管理"]
categories: ["技術"]
author: "ブログ管理者"
---

# Lazarusアプリ用ランチャーの作成 - Day19

Lazarusチャレンジ19日目です。今回は、**Lazarusアプリ用のランチャー（メニューアプリ）**を作成しました。day001からday018まで、たくさんのアプリができたので、それらを管理・起動するためのアプリがあると便利かな、と思いました。

## 今回の目標

今回作成するランチャーアプリは、以下の機能を実装することを目指しました：

- **アプリ一覧表示**: JSONファイルからアプリ情報を読み込み、ListViewで一覧表示
- **アプリの実行**: 選択したアプリのフォルダ内にあるexeファイルを自動探索して起動
- **自動ビルド機能**: exeファイルが見つからない場合、LazBuildでビルドしてから起動
- **ブログ記事の起動**: 各アプリのブログ記事URLをブラウザで開く
- **LazManagerの起動**: 設定されたLazManagerを起動
- **メモ機能**: 各アプリごとに後日追加したい機能などのメモを保存
- **JSON管理**: アプリ情報をJSONファイルで管理（フォルダ名、タイトル、ブログURL、メモ、有効/無効フラグ）

## ランチャーアプリとは？

ランチャーアプリは、複数のアプリケーションを一箇所から管理・起動できるアプリです。今回作成したランチャーは、Daily-Lazarus-Appsフォルダ内にあるday001～day018の各アプリを管理するために作成しました。

### 主な機能

- **アプリ一覧**: 有効なアプリをday番号順に表示
- **アプリ起動**: フォルダ内のexeファイルを自動探索して実行
- **自動ビルド**: exeファイルが見つからない場合、LazBuildでビルドしてから起動
- **ブログ記事**: 各アプリのブログ記事URLをブラウザで開く
- **メモ管理**: 各アプリごとにメモを保存・編集
- **LazManager連携**: LazManagerを起動してプロジェクトを管理

## LazManagerを使ったプロジェクト作成

まず、LazManagerを起動して、プロジェクト名に「**day019_Menu100**」と入力し、プロジェクトを作成しました。

「**Cursor**」ボタンを押してCursorを起動し、プロジェクトフォルダを開きました。

## Cursorへのプロンプト投入

ランチャーアプリの開発は、ChatGPTに壁打ちしてプロンプトを考えてもらい、そのプロンプトをCursorに投入してはじめました。

### プロンプト: ランチャーアプリの作成

```
Lazarus (Free Pascal) で Windows 向けのデスクトップアプリを作成してください。

目的：
Daily-Lazarus-Apps フォルダ内にある day001～day018 の各アプリを一覧表示し、
exe を自動探索して起動できる「メニューアプリ」を作る。

前提条件：
- 設定は apps.json から読み込む
- apps.json の構造は以下の仕様に従う
  - baseDir : string
  - apps : object
    - キー = アプリのフォルダ名（例: day017_CryptEditor）
    - 値:
      - title : string
      - blogUrl : string
      - notes : string[]
      - enabled : boolean

仕様：
- exe ファイルは json に登録しない
- baseDir\フォルダ名 配下にある最初の *.exe を自動探索して実行する
- enabled = true のアプリのみ表示する
- アプリ一覧は day 番号順にソートする

UI 要件：
- メインフォームに以下を配置
  - TListView（アプリ一覧表示）
  - 実行ボタン（選択中アプリの exe を起動）
  - ブログボタン（blogUrl が空でなければ既定ブラウザで開く）
  - 管理ボタン (LazManagerを開く）
- 選択中アプリの notes を下部に表示（TMemo）
- メモの編集・保存機能

実装要件：
- fpjson, jsonparser を使用する
- JSON の読み込みを行うクラス TAppConfig を作成する
- exe 探索用の関数を実装する
  - 入力: アプリフォルダのフルパス
  - 出力: exe のフルパス（見つからなければ空文字）

その他：
- エラー時は例外ではなく MessageDlg で通知
- 可読性を重視し、1ユニット完結でもよい
```

**AIが実装した内容：**

- **TAppConfigクラス**: JSONファイルの読み込み・保存を担当
  - `ParseJsonFile`: JSONファイルを解析
  - `LoadApps`: アプリ情報を配列に読み込み
  - `GetEnabledApps`: 有効なアプリをday番号順にソートして返す
  - `UpdateAppNotes`: アプリのメモを更新
  - `SaveToFile`: JSONファイルに保存
- **FindExeInFolder関数**: フォルダ内の最初のexeファイルを探索
- **BuildWithLazBuild関数**: exeファイルが見つからない場合、LazBuildでビルド
- **UIコンポーネント**: TListView、実行/ブログ/管理/保存ボタン、TMemo
- **アプリ起動**: TProcessを使用してexeファイルを起動
- **ブログ起動**: cmd.exe経由でブラウザを起動

## 実装のポイント

### JSONファイルの構造

```json
{
  "baseDir": "C:\\Users\\bellm\\source\\repos\\bellyoshi\\Daily-Lazarus-Apps",
  "LazManager": "C:\\Lazarus\\LazManager.exe",
  "apps": {
    "day001_MMKaeru": {
      "title": "MIDIファイル作成 - カエルの歌",
      "blogUrl": "https://yoshiby2nd.netlify.app/posts/lazarus-day001-midi-kaeru/",
      "enabled": true,
      "notes": [
        "後日追加したい機能1",
        "後日追加したい機能2"
      ]
    },
    ...
  }
}
```

- **baseDir**: アプリフォルダのベースディレクトリ
- **LazManager**: LazManagerのパス
- **apps**: アプリ情報のオブジェクト（キーはフォルダ名）

### exeファイルの自動探索

exeファイルはJSONに登録せず、フォルダ内を自動探索します：

```pascal
function FindExeInFolder(const FolderPath: string): string;
var
  SearchRec: TSearchRec;
  ExePath: string;
begin
  Result := '';
  if not DirectoryExists(FolderPath) then
    Exit;
    
  if FindFirst(IncludeTrailingPathDelimiter(FolderPath) + '*.exe', 
               faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          ExePath := IncludeTrailingPathDelimiter(FolderPath) + SearchRec.Name;
          Result := ExePath;
          Break; // 最初の exe を見つけたら終了
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;
```

### day番号順のソート

フォルダ名からday番号を抽出し、それでソートします：

```pascal
function TAppConfig.ExtractDayNumber(const FolderName: string): Integer;
var
  i: Integer;
  DayStr: string;
begin
  Result := 0;
  DayStr := '';
  
  // "day" の後に続く数字を抽出
  i := Pos('day', LowerCase(FolderName));
  if i > 0 then
  begin
    i := i + 3; // "day" の後
    while (i <= Length(FolderName)) and (FolderName[i] in ['0'..'9']) do
    begin
      DayStr := DayStr + FolderName[i];
      Inc(i);
    end;
    if DayStr <> '' then
      Result := StrToIntDef(DayStr, 0);
  end;
end;
```





### ListViewの選択変更イベント

ListViewの選択が変更されたとき、メモを更新します。ここで重要な点は、**LazarusのTListViewには`OnSelectionChange`イベントがなく、`OnSelectItem`イベントを使用する**必要があることです。

最初、`OnSelectionChange`という存在しないイベントを使用しようとしてエラーが発生しましたが、`OnSelectItem`に修正して解決しました。
こちらは最初、実行すると、全く動かずに
Error reading ListViewApps.OnSelectionChange:
Unknown property: "OnSelectionChange".
Press OK to ignore and risk data corruption.
Press Abort to kill the program.
というエラーが出ました。
Geminiに聞いてイベント名が違っていることがわかりました。
IDEで開発していると、間違えることはないのですが、
AIエディターで開発していると、存在しないイベントを実装してしまうことがあります。
コンパイルは通るのではまりやすいです。

## ビルドと実行

Cursorで実装が完了した後、Lazbuildでビルドを実行しました。

```
C:\Lazarus\Lazbuildでビルド
```

ビルドが成功し、実行ファイル `day019_Menu100.exe` が生成されました。

![ランチャーアプリの画面](/images/LazarusDay019.png)

アプリが正常に動作しています！ListViewでアプリを選択し、実行ボタンでアプリを起動、ブログボタンでブログ記事を開くことができます。


### LazBuildによる自動ビルド

ランチャーでアプリを実行するときに実行ファイルがないプロジェクトがあるのに気づきました。
これは、作者がZipファイルをつくるときにexeを削除してソースのみを公開するためです。
そこで、exeファイルが見つからない場合、ユーザーに確認してからLazBuildでビルドする機能を実装しました。

最初の実装では、LazBuildの実行時にデッドロックが発生しました。`poWaitOnExit`オプションを使用してプロセスの終了を待っていたため、パイプのバッファが満杯になり、プロセスが停止してしまったのです。これを解決するために、`poWaitOnExit`を外し、プロセスが動いている間は出力を吸い出し続けるようにしました。これにより、デッドロックを防ぐことができました。




## アプリの機能

完成したランチャーアプリには、以下の機能が実装されています：

- ✅ **アプリ一覧表示**: JSONファイルからアプリ情報を読み込み、ListViewでday番号順に表示
- ✅ **アプリの実行**: 選択したアプリのフォルダ内にあるexeファイルを自動探索して起動
- ✅ **自動ビルド機能**: exeファイルが見つからない場合、LazBuildでビルドしてから起動
- ✅ **ブログ記事の起動**: 各アプリのブログ記事URLをブラウザで開く
- ✅ **LazManagerの起動**: 設定されたLazManagerを起動
- ✅ **メモ機能**: 各アプリごとにメモを保存・編集（後日追加したい機能など）
- ✅ **JSON管理**: アプリ情報をJSONファイルで管理（フォルダ名、タイトル、ブログURL、メモ、有効/無効フラグ）
- ✅ **exe自動探索**: フォルダ内の最初のexeファイルを自動探索
- ✅ **day番号順ソート**: フォルダ名からday番号を抽出してソート

## 学んだこと

Day19の開発を通じて、以下のことを学びました：

### ListViewのイベント

- **OnSelectItemイベント**: LazarusのTListViewには`OnSelectionChange`がなく、`OnSelectItem`を使用する必要がある
- **イベントの違い**: 他のフレームワーク（FireMonkeyなど）には`OnSelectionChange`があるが、LCL（Lazarus Component Library）では`OnSelectItem`が正しい
- **エラーからの学習**: 存在しないイベントを使用しようとしてエラーが発生し、正しいイベント名を学んだ

### JSONファイルの管理

- **fpjsonユニット**: JSONファイルの読み込み・保存に`fpjson`と`jsonparser`を使用
- **TJSONObject**: JSONオブジェクトを扱うためのクラス
- **TJSONArray**: JSON配列を扱うためのクラス
- **データ構造の設計**: アプリ情報をJSONで管理することで、柔軟に拡張可能

### ファイル探索

- **FindFirst/FindNext**: ディレクトリ内のファイルを探索する関数
- **自動探索**: exeファイルをJSONに登録せず、フォルダ内を自動探索することで、管理が簡単になる

### アプリ起動

- **TProcess**: 外部プロセスを起動するためのクラス
- **ブラウザ起動**: cmd.exe経由でブラウザを起動する方法
- **エラーハンドリング**: ファイルが見つからない場合などのエラー処理

### LazBuildによる自動ビルド

- **BuildWithLazBuild関数**: exeファイルが見つからない場合、LazBuildでビルドする機能
- **プロジェクトファイル探索**: フォルダ内の.lpiファイルを自動探索
- **ビルド出力の取得**: パイプを使用してビルド出力を取得し、エラー時に表示
- **デッドロック防止**: プロセスが動いている間、出力を吸い出し続けることでデッドロックを防止
- **ユーザー確認**: exeファイルが見つからない場合、ユーザーに確認してからビルド

### 実用的なアプリの作成

- **ランチャーアプリ**: 複数のアプリを管理するための実用的なアプリ
- **JSON管理**: 設定ファイルをJSONで管理することで、柔軟に拡張可能
- **メモ機能**: 各アプリごとにメモを保存することで、後日追加したい機能などを記録できる

## まとめ

Day19では、Lazarusアプリ用のランチャー（メニューアプリ）を作成しました。

1. **JSONファイルの管理**: アプリ情報をJSONファイルで管理し、柔軟に拡張可能な構造にした
   - baseDir、LazManager、appsオブジェクト
   - 各アプリにtitle、blogUrl、notes、enabledフラグ

2. **exeファイルの自動探索**: exeファイルをJSONに登録せず、フォルダ内を自動探索することで、管理を簡単にした

3. **LazBuildによる自動ビルド**: exeファイルが見つからない場合、LazBuildでビルドしてから起動する機能を実装した

4. **ListViewのイベント**: `OnSelectionChange`ではなく`OnSelectItem`を使用する必要があることを学んだ

5. **メモ機能**: 各アプリごとにメモを保存・編集できる機能を実装した

### 完成したランチャーアプリについて

完成したランチャーアプリは、day001からday018までのアプリを管理・起動するための実用的なアプリです。JSONファイルでアプリ情報を管理し、ListViewで一覧表示、実行ボタンでアプリを起動、ブログボタンでブログ記事を開くことができます。

特に便利なのは、**exeファイルがなくても、ランチャーから直接LazBuildでビルドして起動できる**機能です。これにより、ソースコードだけがある状態でも、ランチャーから簡単にビルドして実行できます。

たくさんのアプリができたので、それらを管理するためのランチャーアプリは非常に便利です。今後も新しいアプリを追加していく際に、このランチャーから簡単に起動できるようになりました。

## ダウンロード

作成したアプリは以下のリンクからダウンロードできます：

[day019_Menu100.zip](/downloads/day019_Menu100.zip)

次回のDay20では、また新しいアプリに挑戦します！

---

*Lazarusチャレンジ Day 19/100*
