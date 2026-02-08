---
title: "Pas2JSでブラウザで動く簡易L-System描画（フラクタル図形）を作る - Day38"
date: 2026-02-07T20:00:00+09:00
draft: false
featured_image: "/images/LazarusDay038.png"
description: "Lazarusチャレンジ38日目。L-System（リンデンマイヤー系）で植物や雪の結晶のようなフラクタル図形をCanvasに描画するアプリをPas2JSで作成。プリセット（木・シダ・コッホ雪の結晶）の切り替えと再帰の深さスライダでリアルタイムに描画が変わるUIを実装。コンパイル時のイベントハンドラ修正（procedure→function、TEventListenerEvent）もまとめました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day038", "JavaScript", "L-System", "フラクタル", "Canvas", "タートルグラフィックス"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSでブラウザで動く簡易L-System描画（フラクタル図形）を作る - Day38

Lazarusチャレンジ38日目です。数式に基づいて植物や雪の結晶のような**フラクタル図形**を描画する **L-System（リンデンマイヤー系）** を、Pas2JS でブラウザの Canvas に実装しました。アルゴリズム主体のアプリは Pascal の得意分野で、再帰的な書き換えとスタック操作で美しい木やシダ、コッホ曲線を描けます。

## L-Systemの基本

L-System は **開始文字列（Axiom）** に **書き換え規則（Rules）** を繰り返し適用して得た文字列を、「亀の歩み」（タートルグラフィックス）として解釈する仕組みです。

- **F**: 線を引いて進む
- **+** / **−**: 右・左に回転
- **\[** / **\]**: 現在の状態（座標・角度）をスタックに保存／復元（枝分かれの表現）

例として「有機的な木」では Axiom を `X`、規則を `F→FF`、`X→F[[+X]-X]-F[-FX]+X` のようにし、角度 25° で描画します。

## 作成したアプリの機能

- **プリセット切り替え**: ドロップダウンで「有機的な木」「シダの葉」「コッホ雪の結晶」を選択。Axiom・Rules・角度をレコードで管理し、切り替え時に再描画
- **再帰の深さスライダ**: 0～6 でルール適用回数を変更。スライダを動かすとリアルタイムに図形が成長
- **グラデーション描画**: 木・シダでは幹から先端に向けて色を茶系から緑系に変化。枝分かれごとに線を細くする演出
- **ステータス表示**: 生成された L-System 文字列の長さを表示

HTML / CSS / Pascal を分離した構成で、`pas2js` でコンパイルした `project1.js` を読み込んで動作します。

## 開発でハマった点（pas2js のイベントハンドラ）

スライダの `OnInput` とセレクトの `OnChange` に `procedure` をそのまま渡すと、コンパイルエラーになりました。

1. **procedure → function に変更**  
   pas2js の `OnInput` / `OnChange` は **関数型（戻り値あり）** を要求するため、`HandleInput` と `HandleSelect` を `function ... : Boolean` にし、末尾で `Result := True` を返すようにしました。

2. **引数の型を TEventListenerEvent に合わせる**  
   コンパイラが「arg no. 1: Got "TEventListenerEvent", expected "TJSInputEvent"」と報告していたため、両ハンドラの第1引数を `TEventListenerEvent` に変更。`HandleSelect` 内では `Event.Target` を `TJSHTMLElement(Event.Target)` でキャストしてから `TJSHTMLSelectElement` として扱うようにしました。

```pascal
function HandleInput(Event: TEventListenerEvent): Boolean;
begin
  Depth := StrToInt(TJSHTMLInputElement(document.GetElementById('depthRange')).Value);
  document.GetElementById('depthVal').InnerHTML := IntToStr(Depth);
  Render;
  Result := True;
end;

function HandleSelect(Event: TEventListenerEvent): Boolean;
begin
  SetPreset(TJSHTMLSelectElement(TJSHTMLElement(Event.Target)).Value);
  Render;
  Result := True;
end;
```

この修正で `pas2js project1.pas -Tbrowser "-Jirtl.js"` によるコンパイルが正常に完了します。

## コンパイル方法

pas2js が入っている環境で、ブラウザ向けにコンパイルします。

```bash
pas2js project1.pas -Tbrowser "-Jirtl.js"
```

生成された `project1.js` を `index.html` から読み込み、`rtl.run()` で実行するとブラウザで動作します。

## 実装のポイント

- **動的スタック**: `array of TState` と `SetLength` で座標・角度・線幅をプッシュ/ポップし、`[` `]` による枝分かれを再現
- **プリセットの型安全な管理**: `TLSystemPreset` レコードに Axiom, RuleF, RuleX, Angle, InitialStep, InitialY をまとめ、`SetPreset(Kind)` で切り替え
- **X 記号**: 描画はしないが書き換えに使うダミー記号として扱い、複雑な分岐パターンを実現

## ダウンロード

**アプリをブラウザで開く**: [L-System Fractal Explorer を開く](/apps/day038/day038_pas2jsLSystem/)

作成したアプリ（HTML / CSS / Pascal ソース・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day038_pas2jsLSystem.zip](/downloads/day038_pas2jsLSystem.zip)

規則や角度を変えるだけで雪の結晶から有機的な低木まで姿が変わるので、パラメータをいじってみると楽しめます。

---

*Lazarusチャレンジ Day 38/100*
