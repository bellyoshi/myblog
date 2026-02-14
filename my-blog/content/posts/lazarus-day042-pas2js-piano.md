---
title: "Pas2JSで作る楽器に変身！「Web音階ジェネレーター」 - Day42"
date: 2026-02-11T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay042.png"
description: "Lazarusチャレンジ42日目。Web Audio APIを叩いて、ボタンを押すとPascalで定義した周波数の音が鳴る「Web音階ジェネレーター」をPas2JSで作成。PascalのCase文で音階（C, D, E...）をスマートに管理し、ピアノの鍵盤イメージで鳴らす。Geminiで骨格・HTML/CSS/PASを取得し、usesにwebaudio追加と「PlayNoteがコンパイルから落ちる」問題をCursorで解決しました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day042", "Web Audio API", "音階", "楽器", "Gemini", "Cursor", "webaudio", "pas2js"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで作る楽器に変身！「Web音階ジェネレーター」 - Day42

Lazarusチャレンジ42日目です。**Web Audio API** を叩いて、ボタンを押すと **Pascal で定義した周波数**の音が鳴る「**Web音階ジェネレーター**」を Pas2JS でブラウザ向けに作りました。**Pascal の Case 文**で音階（C, D, E ...）をスマートに管理し、ピアノの鍵盤のイメージで鳴らす構成にしています。設計とベースコードは **Gemini** に任せ、コンパイルエラーと実行時エラーは **Cursor** で解消しました。

![Web音階ジェネレーター 画面](/images/LazarusDay042.png)

## コンセプト

- **Web Audio API**: ブラウザの `AudioContext` で音の再生環境を作り、`OscillatorNode` で波形（音）を生成、`GainNode` で音量（エンベロープ）を制御
- **Pascal で音階を定義**: 列挙型 `TNote`（C4, D4, E4 ... C5）と **case 文**で「音階名 → 周波数(Hz)」を型安全に変換。マジックナンバーを排除した読みやすいコードになる
- **ピアノ鍵盤のUI**: HTML/CSS で鍵盤風のボタンを並べ、各ボタンの `onclick` で Pascal の `PlayNote` を呼び出して音を鳴らす

| 音階 | 周波数 (Hz) | 役割 |
|------|-------------|------|
| C4 (ド) | 261.63 | 基準となるド |
| A4 (ラ) | 440.00 | 調律の基準（時報の音） |
| C5 (ド) | 523.25 | 1オクターブ上 |

## Gemini でやったこと

まず **Gemini** に次のようなプロンプトを出して、設計とベースコードを取得しました。

- **「Pas2jsで作る楽器に変身！Web音階ジェネレーター。Web Audio APIを叩いて、ボタンを押すとPascalで定義した周波数の音が鳴る。ユニーク点: PascalのCase文を使って、音階（C, D, E...）をスマートに管理。ピアノの鍵盤のイメージ」**

Gemini からは、**TNote と case 文による NoteToFreq**、**Web Audio API（AudioContext / OscillatorNode / GainNode）との連携案**、**エンベロープや波形（sine / square / sawtooth）のアドバイス**が返ってきました。続けて「**htmlとcssとpasを出すように**」とプロンプトし、コピー＆貼り付け用のコードを出力させています。Cursor は課金利用だが $20 で足りなくなるため、ベース部分は Gemini に任せる方針です。

## コンパイルが通らない → Cursor にスイッチ

Gemini からもらったコードで、次のコマンドを実行すると **コンパイルエラー**になりました。

```bash
pas2js .\project.pas -Tbrowser "-Jirtl.js"
```

Cursor を起動し、「**pas2js .\project.pas -Tbrowser "-Jirtl.js" 実行とプロンプト**」でコンパイル完了を依頼しました。このとき **uses に `webaudio` が含まれていなかった**ため、Pas2js が Web Audio API 用の正しいコードを生成せず、無駄なコードが混ざっていました。**作業を中断して自分で uses に `webaudio` を追加**し、再度同じコマンドでコンパイルを実行する。
最初usesにwebaudioがなかったため、無駄なコードを吐き出しました。
それでいったんCursorの作業をとめ自分でusesの修正をし再度プロンプトすると、いくつかの修正の後 **コンパイルは完了**しました。

## 実行時エラー：PlayNote is not a function

ブラウザで実行すると、鍵盤ボタンを押したときに次のエラーが出ました。

```
TypeError: pas.PlayNote is not a function
    at HTMLButtonElement.onclick
```

**原因**: `PlayNote` は **HTML の onclick からしか参照されていなかった**ため、**Pas2js のコンパイル時に「参照されていない」と判断され、出力 JS に含まれていなかった**ことです。Pas2js はコンパイル時に対象ユニット内の参照だけを見るため、HTML に書いた `onclick="pas.PlayNote('C4')"` のような呼び出しは「参照」としてカウントされません。

## 解決策：参照を残しつつ JavaScript に公開

次の2つを Pascal 側に追加しました。

1. **絶対に通らないコードで参照を残す**  
   コンパイラに「PlayNote が使われている」と認識させるため、**絶対に実行されない分岐**で呼び出しを書きます。

   ```pascal
   if false then PlayNote('C4');
   ```

2. **JavaScript から呼べるようにグローバルに公開**  
   HTML の `pas.PlayNote(...)` で呼べるよう、`window.pas` に Pascal の `PlayNote` を渡します。

   ```pascal
   asm
     window.pas = { PlayNote: $mod.PlayNote };
   end;
   ```

これで `PlayNote` がコンパイル対象に含まれ、かつ HTML の onclick から `pas.PlayNote('C4')` などで正しく呼び出せるようになり、**音が鳴る**ようになりました。

## 作成したアプリの機能（抜粋）

- **音階と周波数**: Pascal の case 文で C4〜C5 の各音を Hz に変換（261.63, 293.66, ... 523.25）
- **Web Audio API**: AudioContext / OscillatorNode / GainNode で、短いエンベロープを付けて音を鳴らす
- **ピアノ鍵盤風UI**: 各鍵盤ボタンの onclick で `pas.PlayNote('C4')` のように音名を渡して再生
- **波形**: sine（基本）、square / sawtooth に変えるとファミコン風の音にも変更可能

## コンパイル方法（Pas2JS）

```bash
pas2js project.pas -Tbrowser -Jirtl.js
```

`index.html` から生成された `project.js` を読み込み、`rtl.run()` でプログラムを開始します。**uses に `web` と `webaudio`** を入れておくことがポイントです。

## まとめ：Gemini と Cursor の役割

- **Gemini**: プロンプトで「Web音階ジェネレーター」「Case 文で音階管理」「ピアノの鍵盤」と伝え、設計と **HTML / CSS / PAS のベースコード**を一括で出力。コストを抑えるためにベース部分をここで作成。
- **Cursor**: **コンパイルが通らない**ときは uses の修正を自分で行い、**実行時エラー**（`pas.PlayNote is not a function`）は「PlayNote が参照されていないためコンパイルから落ちている」と説明し、**`if false then PlayNote('C4');` と `window.pas` へのエクスポート**で解決。

「**ブラウザで Pascal が鳴り響く**」という試みは、Pas2js と Web Audio API の組み合わせで実現できました。HTML から呼ぶ関数は、**Pascal 側で明示的に参照とエクスポートを書く**という Pas2js の性質を押さえておくと、同様のトラブルを防げます。

## ダウンロード

**アプリをブラウザで開く**: [Web音階ジェネレーターを開く](/apps/day042/)

作成したアプリ（HTML / CSS / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day042_pas2jspiano.zip](/downloads/day042_pas2jspiano.zip)

鍵盤を押すと Pascal で定義した周波数の音が鳴る、シンプルな Web 楽器としてそのまま遊べます。波形を変えたり、エンベロープを調整したりして、好みの音にカスタマイズしてみてください。

---

*Lazarusチャレンジ Day 42/100*
