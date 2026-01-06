---
title: "世界時計アプリの作成 - Day6"
date: 2026-01-06T21:32:02+09:00
draft: false
featured_image: "/images/LazarusDay006.png"
description: "Lazarusチャレンジ6日目。Antigravityを使って世界時計アプリを作成しました。SVGで地図を作成し、PythonでBMPに変換して表示するアプリを完成させました。"
tags: ["Lazarus", "GUI", "チャレンジ", "Day006", "Pascal", "時計", "World Clock", "SVG", "Python"]
categories: ["技術"]
author: "ブログ管理者"
---

# 世界時計アプリの作成 - Day6

Lazarusチャレンジ6日目です。今回は、**Antigravity**を使って、**世界時計アプリ**を作成することにしました。

## 今回の目標

今回は、世界の主要都市の現在時刻を地図上に表示するアプリを作成することにしました。以下の手順で進めることにしました：

1. **簡単な世界地図をSVGで作成**: シンプルなSVGファイルで世界地図を表現
2. **SVGをBMPに変換するPythonプログラムを実行**: PythonスクリプトでSVGをBMP形式に変換
3. **世界の主要都市の時計を表示するアプリを作成**: Lazarusアプリで地図を背景に、各都市の時刻を表示

## LazManagerを使ったプロジェクト作成

まず、LazManagerを起動して、プロジェクト名に「**day006_worldclock**」と入力し、プロジェクトを作成しました。

「**Antigravity**」ボタンを押してAntigravityを起動し、プロジェクトフォルダを開きました。

## 計画の作成

まず、Antigravityに以下のような計画を立ててもらいました。
ちなみにAntigravityの方は課金はしていません。たまにしか使わないので無料版でも問題ないです。

’
簡単な世界地図をsvgで作成しなさい。
svgをbmpに変換するpythonのプログラムを実行しなさい。
世界の主要都市の時計を表示するアプリを作成しなさい。’
とプロンプト。
Cursorのようにいきなり生成が始まるのではなく、
計画の承認を求めてきます。

```
'World Clock Application Implementation Plan
Goal Description
Create a "World Clock" application that displays the current time for major cities on a world map. The map will be generated as a simple SVG, converted to BMP using a Python script, and then displayed in a Lazarus/Free Pascal GUI application.

Proposed Changes
Assets
[NEW] world_map.svg
A simple, abstract representation of the world map using basic SVG shapes (ellipses/paths).
Python Tools
[NEW] convert_map.py
A script to convert world_map.svg to world_map.bmp.
Strategy: Will attempt to use cairosvg if available, or svglib. If standard heavy libraries are missing, fallback to a lighter approach or ask user.
Output: c:\Users\bellm\source\repos\bellyoshi\Daily-Lazarus-Apps\day006_worldclock\world_map.bmp
Lazarus Application (day006_worldclock)
[NEW] day006_worldclock.lpr
Main program file.
[NEW] unit1.pas & unit1.lfm
Main Form:
TImage: Displays world_map.bmp as the background.
TLabel: Displays time for specific cities (e.g., Tokyo, London, New York).
TTimer: Updates the clocks every second.
Logic:
Load the BMP at startup.
Calculate offsets for timezones.
Verification Plan
Automated Tests
Run python convert_map.py and verify world_map.bmp exists.
Manual Verification
Compile and run the Lazarus application.
visually inspect if the map is loaded.
Verify clocks are ticking and showing correct relative times.'
```

英文で書かれた計画で、内容は理解できませんが(笑)、この計画に従って実装を進めることにしました。

## 実装

計画ができたので、Antigravityに「**計画通り実行してください**」とお願いしました。

このプロンプトで、以下のファイルが作成されました：

- **world_map.svg**: シンプルな世界地図のSVGファイル
- **convert_map.py**: SVGをBMPに変換するPythonスクリプト
- **day006_worldclock.lpr**: メインプログラムファイル
- **unit1.pas & unit1.lfm**: メインフォームのユニット

## SVG地図の作成と変換

まず、`world_map.svg`が作成されました。これは、基本的なSVG図形（多角形など）を使って、世界地図を抽象的に表現したものです。

次に、`convert_map.py`が実行され、SVGファイルがBMP形式に変換されました。Pythonスクリプトは、cairosvgやsvglibなどのライブラリを使用して変換を行いました。

## アプリケーションの実装

Lazarusアプリケーションには、以下の機能が実装されました：

- **TImage**: 世界地図のBMP画像を背景として表示
- **TLabel**: 各都市（Tokyo、London、New York）の現在時刻を表示
- **TTimer**: 1秒ごとに時刻を更新

タイムゾーンの計算も実装され、各都市の現在時刻が正しく表示されるようになりました。

## ビルドと実行

ビルドが成功したので、早速実行してみました。

![世界時計アプリの実行画面](/images/LazarusDay006.png)

アプリが正常に動作しています！地図が背景に表示され、3つの都市（New York、London、Tokyo）の現在時刻が表示されています。

背景が青と白に分かれているのは、昼と夜を表現しているようです。各都市の時刻も正しく表示されており、時計も1秒ごとに更新されています。

## 完成したアプリの機能

完成した世界時計アプリには、以下の機能が実装されています：

- ✅ **世界地図の表示**: SVGから変換したBMP画像を背景として表示
- ✅ **主要都市の時刻表示**: New York、London、Tokyoの3都市の現在時刻を表示
- ✅ **リアルタイム更新**: 1秒ごとに時刻を更新
- ✅ **タイムゾーン対応**: 各都市のタイムゾーンに応じた時刻を表示

## 改善の余地

完成したアプリを実行してみると、いくつか改善の余地があることがわかりました：

### 地図がシンプルすぎる

現在の地図は、緑色の多角形で大陸を表現した非常にシンプルなものです。もっと詳細な地図にすると、より見やすくなるかもしれません。

### 都市が少ない

現在は3つの都市（New York、London、Tokyo）しか表示されていません。他の主要都市（Paris、Sydney、Moscowなど）も追加すると、より実用的なアプリになるでしょう。

### 視覚的な改善

- 都市の位置を地図上にマーカーで表示
- 時刻表示のフォントサイズや色の調整
- 昼と夜の表現をより分かりやすく

これらの改善は、今後の課題として残っています。

## 学んだこと

Day6の開発を通じて、以下のことを学びました：

### 計画の重要性

今回は、最初に詳細な計画を立ててもらったことで、スムーズに開発を進めることができました。
Antigravity動かねー。と最初は思っていましたが、何事も承認は大事です。

### 外部ツールの活用

今回は、Pythonスクリプトを使ってSVGをBMPに変換しました。Lazarusアプリだけでなく、外部ツールを活用することで、より柔軟な開発が可能になりました。

- **Pythonスクリプト**: SVGからBMPへの変換をPythonで実装
- **ツールチェーン**: 複数のツールを組み合わせて開発

### シンプルな実装の価値

最初のバージョンは、地図もシンプルで、都市も3つだけですが、基本的な機能は実装されています。

- **MVP（最小限の製品）**: まずは動作するバージョンを作成
- **段階的な改善**: 後から機能を追加していくアプローチ

### 視覚的な表現の難しさ

世界地図をSVGで表現するのは、思っていたよりも難しかったです。

- **抽象化のバランス**: 詳細すぎず、シンプルすぎない表現が難しい
- **視覚的な分かりやすさ**: ユーザーにとって分かりやすい表現を考える必要がある

## まとめ

Day6では、LazManagerを使って世界時計アプリを作成しました。

1. **計画の作成**: 最初に詳細な計画を立てることで、スムーズに開発を進めることができた

2. **SVG地図の作成**: シンプルなSVGファイルで世界地図を表現

3. **Pythonスクリプト**: SVGをBMPに変換するPythonスクリプトを作成

4. **Lazarusアプリ**: 地図を背景に、主要都市の時刻を表示するアプリを実装

5. **改善の余地**: 地図の詳細化や都市の追加など、今後の改善点が明確になった

### 完成した世界時計アプリについて

完成した世界時計アプリは、基本的な機能が実装されており、動作する状態になっています。3つの主要都市の時刻が表示され、1秒ごとに更新されます。ただし、地図がシンプルで、都市も少ないため、今後の改善の余地があります。

## 今後の改善案

次回以降、以下のような改善を行うことで、より実用的なアプリになるでしょう：

- **地図の詳細化**: より詳細な世界地図を使用
- **都市の追加**: より多くの主要都市を追加
- **視覚的な改善**: マーカーの追加、フォントの調整など
- **機能の追加**: タイムゾーンの選択、カスタム都市の追加など

## ダウンロード

作成したアプリは以下のリンクからダウンロードできます：

[day006_worldclock.zip](/downloads/day006_worldclock.zip)

次回のDay7では、また新しいアプリに挑戦します！

---

*Lazarusチャレンジ Day 6/100*

